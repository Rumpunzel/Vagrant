@tool
class_name AdventureEventScreen
extends VBoxContainer

## An event on one screen. A plain event: its section with its pages as a graph. A scenario or encounter: whether it shows the first option that
## fits or all of them, when (its own conditions), and a foldable section per option in order (▲ ▼ reorder, ✕ takes one out, its file stays) with the option's pages as a graph inside. An encounter adds its
## story ([AdventureStoryline]): a bar per stage track with its stages, and per option the stages it can happen in (click to change them) and
## where its decisions lead. Picking a stage in a bar dims what can't happen then and marks what leads into it.

signal event_opened(event: AdventureEvent, host: AdventurePage)
signal changes_requested(changes: Array[Array], action: String, file: Resource)
## A new event as the last option of [param scenario]
signal option_requested(scenario: AdventureEventScenario)
## Pick an event made already as the last option; [param show_actions] shows the choices
## A ready option searching [param encounter]'s dead monster ([method AdventureMakers.make_loot_event])
signal loot_event_requested(encounter: AdventureEncounter)
signal existing_option_requested(scenario: AdventureEventScenario, show_actions: Callable)
## Ask for a name, then call [param then] with it
## [param value]: the name it has now, when renaming
signal text_requested(title: String, label: String, then: Callable, value: String)
## Play from [param page], [param event] shown whatever its conditions
signal play_requested(page: AdventurePage, event: AdventureEvent)
## Delete [param event]'s file, and what lists or points to it (asked first)
signal deletion_requested(event: AdventureEvent)

const DIMMED: Color = Color(1, 1, 1, 0.35)
const LEADS_IN_COLOR: Color = Color(0.6, 1.0, 0.6)
const UNKNOWN_COLOR: Color = Color(1, 0.55, 0.5)
const GRAPH_HEIGHT_MIN: float = 220.0
const GRAPH_HEIGHT_MAX: float = 640.0
const GRAPH_MARGIN: float = 90.0
## The bar under a graph to drag its height with
const HANDLE_HEIGHT: float = 8.0

## By [enum AdventureEventScenario.Pick]
const PICK_TEXTS: Array[String] = ["The first that fits", "Every one that fits"]

## Makes an event graph wired up like the editor's others ([AdventureEventView]); set by [AdventureEditor]
var make_graph: Callable
## Rich tooltips for the stages; none: plain ones
var tooltips: AdventureTooltips

var _event: AdventureEvent
## The event shown, if it is a scenario or encounter
var _scenario: AdventureEventScenario
var _storyline: AdventureStoryline
var _host: AdventurePage
## [track, stage] picked in a bar; empty: none
var _picked: Array = [ ]
## Unfolded options, kept while it is shown
var _open: Array[AdventureEvent] = [ ]
var _title: Label
## Where the scenario's "shows the first / every option that fits" goes
var _pick: HBoxContainer
var _add_track: Button
var _add_option: Button
var _add_existing: Button
var _add_loot_event: Button
## The graphs of the unfolded sections
var _graphs: Array[AdventureEventView] = [ ]
var _info: Label
var _tracks: VBoxContainer
var _scroll: ScrollContainer
var _sections: VBoxContainer
var _menu: AdventureActionMenu
var _stage_menu: PopupMenu
var _stage_menu_event: AdventureEvent

func setup() -> void:
	_title = Label.new()
	_title.theme_type_variation = &"HeaderMedium"
	add_child(_title)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.modulate = Color(1, 1, 1, 0.8)
	add_child(_info)
	_tracks = VBoxContainer.new()
	add_child(_tracks)
	var bar: HBoxContainer = HBoxContainer.new()
	add_child(bar)
	_pick = HBoxContainer.new()
	bar.add_child(_pick)
	_add_option = AdventureUi.text_button("Option", "Add", "A new event as the last option", func() -> void: option_requested.emit(_scenario))
	bar.add_child(_add_option)
	_add_existing = AdventureUi.text_button("Add event…", "Add", "An event made already as the last option", func() -> void: existing_option_requested.emit(_scenario, _menu.show_actions))
	bar.add_child(_add_existing)
	var loot_tip: String = "An option to search its monster once it is dead (change its condition for, say, a sleeping one)"
	_add_loot_event = AdventureUi.text_button("Loot event", "Search", loot_tip, func() -> void: loot_event_requested.emit(_scenario as AdventureEncounter))
	bar.add_child(_add_loot_event)
	_add_track = AdventureUi.text_button("Track", "Add", "A new stage track: a line of the story, one stage at a time", _ask_for_track)
	bar.add_child(_add_track)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	_sections = VBoxContainer.new()
	_sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_sections)
	_menu = AdventureActionMenu.new()
	add_child(_menu)
	_stage_menu = PopupMenu.new()
	_stage_menu.hide_on_checkable_item_selection = false
	_stage_menu.index_pressed.connect(_on_stage_toggled)
	add_child(_stage_menu)

func get_event() -> AdventureEvent: return _event

func get_host() -> AdventurePage: return _host

## [param host]: where it is looked at from (the "At:" picker); [param focus]: an option to unfold and scroll to
func show_event(event: AdventureEvent, host: AdventurePage, focus: AdventureEvent = null) -> void:
	var scenario: AdventureEventScenario = event as AdventureEventScenario
	if event != _event:
		_picked = [ ]
		_open.clear()
		if scenario != null and not scenario.events.is_empty(): _open.append(scenario.events[0])
		if scenario == null and event != null: _open.append(event)
	if focus != null and not _open.has(focus): _open.append(focus)
	var scrolled: int = _scroll.scroll_vertical
	_event = event
	_scenario = scenario
	_host = host
	_graphs.clear()
	for child: Node in _tracks.get_children() + _sections.get_children(): child.queue_free()
	for control: Control in [_pick, _add_option, _add_existing]: control.visible = scenario != null
	_add_track.visible = event is AdventureEncounter
	_add_loot_event.visible = event is AdventureEncounter and (event as AdventureEncounter).profile is MonsterProfile
	_storyline = null
	if event == null:
		_title.text = "Pick an event"
		_info.visible = false
		return
	if scenario == null:
		_title.text = AdventureGraph.get_title(event)
		_show_info()
		_add_section(event, -1)
		return
	var encounter: AdventureEncounter = scenario as AdventureEncounter
	_storyline = AdventureStoryline.new(encounter) if encounter != null else null
	_title.text = AdventureGraph.get_title(scenario) + (" (encounter)" if encounter != null else " (scenario)")
	for child: Node in _pick.get_children(): child.queue_free()
	_pick.add_child(AdventureUi.choice("Shows", PICK_TEXTS, scenario.pick, [
		"The first option (top to bottom) whose conditions are met",
		"Every option whose conditions are met, top to bottom",
	] as Array[String], _on_pick_selected))
	_show_info()
	if _storyline != null:
		for track_name: String in _storyline.get_track_names(): _add_track_bar(track_name)
	var focused: Control = null
	for index: int in scenario.events.size():
		var section: Control = _add_section(scenario.events[index], index)
		if scenario.events[index] == focus: focused = section
	if scenario.events.is_empty():
		var none: Label = Label.new()
		none.text = "No options yet"
		none.modulate = DIMMED
		_sections.add_child(none)
	if focused != null: _scroll.ensure_control_visible.call_deferred(focused)
	else: _scroll.set_deferred(&"scroll_vertical", scrolled)

func _show_info() -> void:
	var lines: Array[String] = [ ]
	var conditions: String = AdventureEventGraph.describe_conditions(_event.conditions)
	if not conditions.is_empty(): lines.append("When %s" % conditions)
	var encounter: AdventureEncounter = _event as AdventureEncounter
	if encounter != null:
		var places: Array[String] = [ ]
		for location: AdventureLocation in encounter.get_places(): places.append(AdventureGraph.get_title(location))
		lines.append("Could be at %s" % (", ".join(places) if not places.is_empty() else "no place yet (only events shown anywhere or near it)"))
	_info.text = "\n".join(lines)
	_info.visible = not lines.is_empty()

## "Storyline:" (click: rename, remove, Inspector) and a toggle per stage (picking one dims what can't happen then; right-click: rename,
## remove), and + for a new stage; the body's states can't be changed
func _add_track_bar(track_name: String) -> void:
	var track: AdventureStageTrack = AdventureStageTrack.find(_storyline.encounter.tracks, track_name)
	var stages: Array[String] = _storyline.get_stages_of(track_name)
	var bar: HBoxContainer = HBoxContainer.new()
	if track != null:
		var name_button: Button = AdventureUi.text_button("%s:" % track_name, "", "One stage at a time. Click: rename, remove", _show_track_menu.bind(track))
		name_button.flat = true
		bar.add_child(name_button)
	else:
		var label: Label = AdventureUi.label("%s:" % track_name)
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.tooltip_text = "Its monster's body, as the fights leave it (won: beaten) and kills end it"
		bar.add_child(label)
	for stage: String in stages:
		var chip: Button = Button.new()
		chip.text = stage
		chip.toggle_mode = true
		chip.button_pressed = _picked == [track_name, stage]
		chip.tooltip_text = "What can happen while it is %s, and what leads here" % stage
		chip.toggled.connect(_on_stage_picked.bind(track_name, stage))
		if track != null:
			chip.gui_input.connect(func(input: InputEvent) -> void:
				var click: InputEventMouseButton = input as InputEventMouseButton
				if click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT: _show_stage_menu(track, stage)
			)
		if tooltips != null and track != null:
			tooltips.attach(chip, AdventureTooltips.get_stage(_storyline.encounter, track_name, stage), "dim what can't happen while it is %s. Right-click: rename, remove" % stage)
		bar.add_child(chip)
	if track == null:
		_tracks.add_child(bar)
		return
	var add: Button = AdventureUi.text_button("", "Add", "A new stage on %s" % track_name, _ask_for_stage.bind(track))
	add.flat = true
	bar.add_child(add)
	if stages.is_empty():
		var hint: Label = Label.new()
		hint.text = "No stages yet"
		hint.modulate = DIMMED
		bar.add_child(hint)
	_tracks.add_child(bar)

## Rename (with every stage condition and effect about it), remove (only while nothing uses it), Inspector
func _show_track_menu(track: AdventureStageTrack) -> void:
	var uses: int = _storyline.count_uses(track, tooltips.stages) if tooltips != null else 0
	var actions: Dictionary[String, Callable] = {
		"Rename track…": func() -> void: text_requested.emit("Rename track %s" % track.name, "Name", _rename_track.bind(track), track.name),
	}
	if uses == 0: actions["Remove track"] = func() -> void: _request(_storyline.get_changes_removing_track(track), "Remove track %s" % track.name)
	else: actions["Can't remove: %s use it" % _count_uses(uses)] = Callable()
	actions["Show in the Inspector"] = EditorInterface.edit_resource.bind(track)
	_menu.show_actions(actions)

func _show_stage_menu(track: AdventureStageTrack, stage: String) -> void:
	var uses: int = _storyline.count_uses(track, tooltips.stages, stage) if tooltips != null else 0
	var actions: Dictionary[String, Callable] = {
		"Rename stage…": func() -> void: text_requested.emit("Rename %s: %s" % [track.name, stage], "Name", _rename_stage.bind(track, stage), stage),
	}
	if uses == 0: actions["Remove stage"] = func() -> void: _request(_storyline.get_changes_removing_stage(track, stage), "Remove stage %s: %s" % [track.name, stage])
	else: actions["Can't remove: %s use it" % _count_uses(uses)] = Callable()
	_menu.show_actions(actions)

static func _count_uses(uses: int) -> String: return "1 condition or effect" if uses == 1 else "%d conditions and effects" % uses

func _rename_track(new_name: String, track: AdventureStageTrack) -> void:
	if new_name == track.name or AdventureStageTrack.find(_storyline.encounter.tracks, new_name) != null: return
	_request(_storyline.get_changes_renaming_track(track, new_name, tooltips.stages), "Rename track %s to %s" % [track.name, new_name])

func _rename_stage(new_name: String, track: AdventureStageTrack, stage: String) -> void:
	if track.stages.has(new_name): return
	_request(_storyline.get_changes_renaming_stage(track, stage, new_name, tooltips.stages), "Rename %s: %s to %s" % [track.name, stage, new_name])

func _rename_option(title: String, option: AdventureEvent) -> void:
	_request([[option, &"title", title, AdventureEventEditing.get_file(option)]] as Array[Array], "Rename %s to %s" % [_describe(option), title])

## A foldable section: its title, where it can happen and leads, ▲ ▼ ✕ in the title bar; unfolded, its pages (a scenario: a way to open it).
## [param index]: its place among the options; -1: the event shown on its own
func _add_section(option: AdventureEvent, index: int) -> Control:
	var section: FoldableContainer = FoldableContainer.new()
	section.title = "%d · %s" % [index + 1, _describe(option)] if index >= 0 else _describe(option)
	section.folded = not _open.has(option)
	_sections.add_child(section)
	if option == null: return section
	var dimmed: bool = _storyline != null and not _picked.is_empty() and not _storyline.can_happen_in(option, _picked[0], _picked[1])
	if dimmed: section.modulate = DIMMED
	if _storyline != null: _add_story_controls(section, option)
	elif index >= 0:
		var needs: String = AdventureEventGraph.describe_conditions(option.conditions)
		section.add_title_bar_control(AdventureUi.label("when %s" % needs if not needs.is_empty() else "always fits"))
	section.folding_changed.connect(_on_folding_changed.bind(section, option))
	if not section.folded: _fill_section(section, option)
	if not option is AdventureEventScenario:
		section.add_title_bar_control(AdventureUi.icon_button("Play", "", "Play from here: the game starts at its location with it shown, whatever its conditions", play_requested.emit.bind(option, option)))
	section.add_title_bar_control(AdventureUi.icon_button("Edit", "", "Rename it", func() -> void: text_requested.emit("Rename %s" % _describe(option), "Title", _rename_option.bind(option), option.title)))
	if not AdventureEventEditing.is_inside_file(option):
		section.add_title_bar_control(AdventureUi.icon_button("Remove", "", "Delete it: its file goes to the system trash, and it is no option anywhere any more", deletion_requested.emit.bind(option)))
	if index < 0: return section
	if index > 0: section.add_title_bar_control(AdventureUi.icon_button("MoveUp", "", "Earlier: checked first", _move.bind(index, -1)))
	if index < _scenario.events.size() - 1: section.add_title_bar_control(AdventureUi.icon_button("MoveDown", "", "Later", _move.bind(index, 1)))
	var remove: Button = AdventureUi.icon_button("Unlinked", "", "Not an option here any more (its file stays)", _remove.bind(index))
	remove.disabled = AdventureEventEditing.is_inside_file(option)
	section.add_title_bar_control(remove)
	section.add_title_bar_control(AdventureUi.icon_button("Object", "", "Show it in the Inspector", EditorInterface.edit_resource.bind(option)))
	return section

func _on_folding_changed(is_folded: bool, section: FoldableContainer, option: AdventureEvent) -> void:
	if is_folded:
		_open.erase(option)
		return
	if not _open.has(option): _open.append(option)
	if section.get_child_count() == 0: _fill_section(section, option)

## Its pages as a graph, about as high as they need; a scenario option opens on its own
func _fill_section(section: FoldableContainer, option: AdventureEvent) -> void:
	if option is AdventureEventScenario:
		var open: Button = AdventureUi.text_button("Open its options", "GraphEdit", "A scenario inside: its own options", event_opened.emit.bind(option, _host))
		open.icon = AdventureActionMenu.get_event_icon(option)
		section.add_child(open)
		return

	var graph: AdventureEventView = make_graph.call()
	graph.outer_scroll = _scroll
	graph.picked_stage = _picked
	graph.custom_minimum_size.y = GRAPH_HEIGHT_MIN
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 0)
	section.add_child(column)
	column.add_child(graph)
	column.add_child(_make_handle(graph, AdventureLayout.get_key(option)))
	graph.setup()
	graph.show_event(option, _host)
	var settings: Control = graph.make_settings()
	column.add_child(settings)
	column.move_child(settings, 0)
	# The graph's own tools (zoom, grid, Tidy, Host / Previous to drag in) in a strip above it, not over its nodes
	var tools: HBoxContainer = graph.get_menu_hbox()
	tools.get_parent().remove_child(tools)
	column.add_child(tools)
	column.move_child(tools, 1)
	_graphs.append(graph)
	var key: String = AdventureLayout.get_key(option)
	var height: float = graph.layout.graph_heights.get(key, 0.0) if graph.layout != null else 0.0
	if height > 0.0: graph.custom_minimum_size.y = height
	get_tree().process_frame.connect(_fit_and_frame.bind(graph, height <= 0.0), CONNECT_ONE_SHOT)

## Once its nodes are laid out: as high as they need (unless a height is kept), then every node in view (the frame after, at that height)
func _fit_and_frame(graph: AdventureEventView, fit: bool) -> void:
	if not is_instance_valid(graph): return
	if fit: _fit(graph)
	get_tree().process_frame.connect(_frame.bind(graph), CONNECT_ONE_SHOT)

func _frame(graph: AdventureEventView) -> void:
	if is_instance_valid(graph): graph.frame_nodes()

## A bar to drag [param graph]'s height with; let go, the height is kept in the layout under [param key]
func _make_handle(graph: AdventureEventView, key: String) -> Control:
	var handle: Panel = Panel.new()
	handle.custom_minimum_size.y = HANDLE_HEIGHT
	handle.mouse_default_cursor_shape = Control.CURSOR_VSIZE
	handle.tooltip_text = "Drag to make the graph higher or lower"
	handle.gui_input.connect(_on_handle_input.bind(graph, key))
	return handle

func _on_handle_input(input: InputEvent, graph: AdventureEventView, key: String) -> void:
	var motion: InputEventMouseMotion = input as InputEventMouseMotion
	if motion != null and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
		graph.custom_minimum_size.y = maxf(GRAPH_HEIGHT_MIN, graph.custom_minimum_size.y + motion.relative.y)
		return
	var click: InputEventMouseButton = input as InputEventMouseButton
	if click == null or click.button_index != MOUSE_BUTTON_LEFT or click.pressed or graph.layout == null: return
	graph.layout.graph_heights[key] = graph.custom_minimum_size.y
	graph.layout_changed.emit()

## As high as its nodes reach, within limits
func _fit(graph: AdventureEventView) -> void:
	if not is_instance_valid(graph): return
	var bottom: float = 0.0
	for child: Node in graph.get_children():
		var element: GraphElement = child as GraphElement
		if element != null: bottom = maxf(bottom, element.position_offset.y + element.size.y)
	graph.custom_minimum_size.y = clampf(bottom * graph.zoom + GRAPH_MARGIN, GRAPH_HEIGHT_MIN, GRAPH_HEIGHT_MAX)

## Where it can happen (click to change) and where it leads; marked if it leads into the picked stage
func _add_story_controls(section: FoldableContainer, option: AdventureEvent) -> void:
	var stages: Array[String] = [ ]
	for track_name: String in _storyline.get_track_names():
		var in_track: Array[String] = _storyline.get_stages_in(option, track_name)
		stages.append("%s: %s" % [track_name, " or ".join(in_track)] if not in_track.is_empty() else "%s: any" % track_name)
	# Its other conditions show as its When chips
	var happens: Button = AdventureUi.text_button("Stages", "", "Can happen in %s. Click: change" % "  ·  ".join(stages), _offer_stages.bind(option))
	happens.flat = true
	section.add_title_bar_control(happens)
	# Where its decisions lead, right after its title
	var leads: Array[String] = [ ]
	for lead: AdventureStoryline.Lead in _storyline.get_leads(option):
		leads.append("%s%s → %s" % [lead.decision.description.get_slice("\n", 0), " · " + lead.outcome.name if not lead.outcome.name.is_empty() else "", lead.stage])
	if not leads.is_empty(): section.title += "      " + "  ·  ".join(leads)
	if not _picked.is_empty() and _storyline.leads_into(option, _picked[0], _picked[1]): section.add_theme_color_override(&"font_color", LEADS_IN_COLOR)
	var unknown: Array[String] = _storyline.get_unknown_stages(option)
	if not unknown.is_empty():
		var warning: Label = AdventureUi.label("⚠ %s" % ", ".join(unknown))
		warning.add_theme_color_override(&"font_color", UNKNOWN_COLOR)
		warning.tooltip_text = "Not stages of their tracks"
		section.add_title_bar_control(warning)

static func _describe(option: AdventureEvent) -> String:
	if option == null: return "(empty)"
	var kind: String = " (scenario)" if option is AdventureEventScenario else " (near)" if option.where == AdventureEvent.Where.NEAR else " (anywhere)" if option.where == AdventureEvent.Where.ANYWHERE else ""
	return AdventureGraph.get_title(option) + kind

func _on_stage_picked(on: bool, track: String, stage: String) -> void:
	_picked = [track, stage] if on else [ ]
	show_event(_event, _host)

## The node of [param resource] in the open graphs, in the middle
func focus_resource(resource: Resource) -> void:
	for graph: AdventureEventView in _graphs: graph.focus_resource(resource)

## The stages to tick for where [param option] can happen
func _offer_stages(option: AdventureEvent) -> void:
	_stage_menu_event = option
	_stage_menu.clear()
	for track_name: String in _storyline.get_track_names():
		_stage_menu.add_separator(track_name)
		var in_track: Array[String] = _storyline.get_stages_in(option, track_name)
		var body: bool = track_name == AdventureStoryline.BODY
		for stage: String in _storyline.get_stages_of(track_name):
			if body: _stage_menu.add_radio_check_item(stage)
			else: _stage_menu.add_check_item(stage)
			_stage_menu.set_item_checked(_stage_menu.item_count - 1, in_track.has(stage))
			_stage_menu.set_item_metadata(_stage_menu.item_count - 1, [track_name, stage])
			_stage_menu.set_item_tooltip(_stage_menu.item_count - 1, "One state at a time; picked again: any" if body else "None ticked on a track: any of its stages")
	_stage_menu.position = DisplayServer.mouse_get_position()
	_stage_menu.reset_size()
	_stage_menu.popup()

func _on_stage_toggled(index: int) -> void:
	var pair: Array = _stage_menu.get_item_metadata(index)
	var on: bool = not _stage_menu.is_item_checked(index)
	_stage_menu.set_item_checked(index, on)
	var title: String = AdventureGraph.get_title(_stage_menu_event)
	changes_requested.emit(_storyline.get_changes_toggling(_stage_menu_event, pair[0], pair[1]), "%s %s in %s: %s" % [title, "happens" if on else "no longer happens", pair[0], pair[1]], null)

func _ask_for_track() -> void:
	if _storyline != null: text_requested.emit("New track", "Name", _add_named_track, "")

func _add_named_track(track_name: String) -> void:
	_request(_storyline.get_changes_adding_track(track_name), "New track %s" % track_name)

func _ask_for_stage(track: AdventureStageTrack) -> void:
	text_requested.emit("New stage on %s" % track.name, "Name", _add_stage.bind(track), "")

func _add_stage(stage: String, track: AdventureStageTrack) -> void:
	_request(_storyline.get_changes_adding_stage(track, stage), "New stage %s: %s" % [track.name, stage])

func _on_pick_selected(pick: int) -> void:
	_request([[_scenario, &"pick", pick, AdventureEventEditing.get_file(_scenario)]] as Array[Array], "%s: shows %s" % [AdventureGraph.get_title(_scenario), PICK_TEXTS[pick].to_lower()])

func _move(index: int, step: int) -> void:
	var options: Array[AdventureEvent] = _scenario.events.duplicate()
	var option: AdventureEvent = options.pop_at(index)
	options.insert(index + step, option)
	_request(AdventureEventEditing.get_changes_listing(_scenario, options), "Move %s" % _describe(option))

func _remove(index: int) -> void:
	var options: Array[AdventureEvent] = _scenario.events.duplicate()
	var option: AdventureEvent = options.pop_at(index)
	_request(AdventureEventEditing.get_changes_listing(_scenario, options), "Remove %s from %s" % [_describe(option), AdventureGraph.get_title(_scenario)])

func _request(changes: Array[Array], action: String) -> void:
	if not changes.is_empty(): changes_requested.emit(changes, action, null)
