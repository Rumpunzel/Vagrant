@tool
class_name AdventureScenarioView
extends VBoxContainer

## A scenario or encounter on one screen: whether it shows the first option that fits or all of them, when (its own conditions), and its options
## in order (▲ ▼ reorder, ✕ takes one out, its file stays). An encounter adds its story ([AdventureStoryline]): a bar per stage track with its
## stages, and per option the stages it can happen in (click the cell to change them) and where its decisions lead. Picking a stage in a bar
## dims what can't happen then and marks what leads into it. Selecting a row shows it in the Inspector; double-click an option to open it.

signal event_opened(event: AdventureEvent, host: AdventurePage)
signal changes_requested(changes: Array[Array], action: String, file: Resource)
## A new event as the last option of [param scenario]
signal option_requested(scenario: AdventureEventScenario)
## Pick an event made already as the last option; [param show_actions] shows the choices
signal existing_option_requested(scenario: AdventureEventScenario, show_actions: Callable)
## Ask for a name, then call [param then] with it
signal text_requested(title: String, label: String, then: Callable)

enum Act { UP, DOWN, REMOVE }
enum Column { OPTION, IN, LEADS }

const DIMMED: Color = Color(1, 1, 1, 0.35)
const LEADS_IN_COLOR: Color = Color(0.6, 1.0, 0.6)
const UNKNOWN_COLOR: Color = Color(1, 0.55, 0.5)

var _scenario: AdventureEventScenario
var _storyline: AdventureStoryline
var _host: AdventurePage
## [track, stage] picked in a bar; empty: none
var _picked: Array = [ ]
var _title: Label
var _pick: OptionButton
var _add_track: Button
var _info: Label
var _tracks: VBoxContainer
var _tree: Tree
var _menu: AdventureActionMenu
var _stage_menu: PopupMenu
var _stage_menu_event: AdventureEvent

func setup() -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	add_child(bar)
	_title = Label.new()
	_title.theme_type_variation = &"HeaderMedium"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_title)
	_pick = OptionButton.new()
	_pick.add_item("Shows the first option that fits", AdventureEventScenario.Pick.FIRST)
	_pick.add_item("Shows every option that fits", AdventureEventScenario.Pick.ALL)
	_pick.item_selected.connect(_on_pick_selected)
	bar.add_child(_pick)
	bar.add_child(_make_button("Option", "A new event as the last option", func() -> void: option_requested.emit(_scenario)))
	bar.add_child(_make_button("Add event…", "An event made already as the last option", func() -> void: existing_option_requested.emit(_scenario, _menu.show_actions)))
	_add_track = _make_button("Track", "A new stage track: a line of the story, one stage at a time", _ask_for_track)
	bar.add_child(_add_track)
	_info = Label.new()
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.modulate = Color(1, 1, 1, 0.8)
	add_child(_info)
	_tracks = VBoxContainer.new()
	add_child(_tracks)
	_tree = Tree.new()
	_tree.hide_root = true
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.item_selected.connect(_on_item_selected)
	_tree.item_activated.connect(_on_item_activated)
	_tree.item_mouse_selected.connect(_on_item_clicked)
	_tree.button_clicked.connect(_on_button_clicked)
	add_child(_tree)
	_menu = AdventureActionMenu.new()
	add_child(_menu)
	_stage_menu = PopupMenu.new()
	_stage_menu.hide_on_checkable_item_selection = false
	_stage_menu.index_pressed.connect(_on_stage_toggled)
	add_child(_stage_menu)

## [param host]: where it is looked at from (the "At:" picker), passed on when an option is opened
func show_scenario(scenario: AdventureEventScenario, host: AdventurePage) -> void:
	if scenario != _scenario: _picked = [ ]
	_scenario = scenario
	_host = host
	_tree.clear()
	for child: Node in _tracks.get_children(): child.queue_free()
	if scenario == null: return
	var encounter: AdventureEncounter = scenario as AdventureEncounter
	_storyline = AdventureStoryline.new(encounter) if encounter != null else null
	_title.text = AdventureGraph.get_title(scenario) + (" (encounter)" if encounter != null else " (scenario)")
	_pick.select(_pick.get_item_index(scenario.pick))
	_add_track.visible = encounter != null
	_show_info()
	if _storyline != null:
		for track: AdventureStageTrack in encounter.tracks: if track != null: _add_track_bar(track)
	_tree.columns = 3 if _storyline != null else 2
	_tree.column_titles_visible = _storyline != null
	if _storyline != null:
		_tree.set_column_title(Column.OPTION, "Option")
		_tree.set_column_title(Column.IN, "Happens in (click to change)")
		_tree.set_column_title(Column.LEADS, "Leads to")
	_tree.set_column_expand_ratio(Column.OPTION, 2)
	_tree.set_column_expand_ratio(Column.IN, 2)
	if _storyline != null: _tree.set_column_expand_ratio(Column.LEADS, 2)
	var root: TreeItem = _tree.create_item()
	for index: int in scenario.events.size(): _add_option(root, index)
	if scenario.events.is_empty(): _tree.create_item(root).set_text(0, "(no options yet)")

func _show_info() -> void:
	var lines: Array[String] = [ ]
	var conditions: String = AdventureEventOverview.get_condition_text(_scenario.conditions)
	if not conditions.is_empty(): lines.append("When %s" % conditions)
	var encounter: AdventureEncounter = _scenario as AdventureEncounter
	if encounter != null:
		var places: Array[String] = [ ]
		for location: AdventureLocation in encounter.get_places(): places.append(AdventureGraph.get_title(location))
		lines.append("Could be at %s" % (", ".join(places) if not places.is_empty() else "no place yet (only events shown anywhere or near it)"))
	_info.text = "\n".join(lines)
	_info.visible = not lines.is_empty()

## "Storyline:" and a toggle per stage (picking one dims what can't happen then), and + for a new stage
func _add_track_bar(track: AdventureStageTrack) -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	label.text = "%s:" % track.name
	label.tooltip_text = "One stage at a time; rename or remove stages in the Inspector"
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.gui_input.connect(func(input: InputEvent) -> void: _inspect_on_click(input, track))
	bar.add_child(label)
	for stage: String in track.stages:
		var chip: Button = Button.new()
		chip.text = stage
		chip.toggle_mode = true
		chip.button_pressed = _picked == [track.name, stage]
		chip.tooltip_text = "What can happen while it is %s, and what leads here" % stage
		chip.toggled.connect(_on_stage_picked.bind(track.name, stage))
		bar.add_child(chip)
	var add: Button = _make_button("", "A new stage on %s" % track.name, _ask_for_stage.bind(track))
	add.flat = true
	bar.add_child(add)
	if track.stages.is_empty():
		var hint: Label = Label.new()
		hint.text = "No stages yet"
		hint.modulate = DIMMED
		bar.add_child(hint)
	_tracks.add_child(bar)

func _inspect_on_click(input: InputEvent, resource: Resource) -> void:
	var click: InputEventMouseButton = input as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT: EditorInterface.edit_resource(resource)

func _add_option(root: TreeItem, index: int) -> void:
	var option: AdventureEvent = _scenario.events[index]
	var item: TreeItem = _tree.create_item(root)
	item.set_metadata(0, option)
	if option == null:
		item.set_text(Column.OPTION, "%d · (empty)" % (index + 1))
		return
	var kind: String = " (scenario)" if option is AdventureEventScenario else " (near)" if option.where == AdventureEvent.Where.NEAR else " (anywhere)" if option.where == AdventureEvent.Where.ANYWHERE else ""
	item.set_text(Column.OPTION, "%d · %s%s" % [index + 1, AdventureGraph.get_title(option), kind])
	if _storyline == null:
		var needs: String = AdventureEventOverview.get_condition_text(option.conditions)
		item.set_text(1, "when %s" % needs if not needs.is_empty() else "always fits")
	else: _fill_story_cells(item, option)
	var last: int = item.get_tree().columns - 1
	if index > 0: item.add_button(last, AdventureActionMenu.get_editor_icon("MoveUp"), Act.UP, false, "Earlier: checked first")
	if index < _scenario.events.size() - 1: item.add_button(last, AdventureActionMenu.get_editor_icon("MoveDown"), Act.DOWN, false, "Later")
	item.add_button(last, AdventureActionMenu.get_editor_icon("Remove"), Act.REMOVE, AdventureEventEditing.is_inside_file(option), "Not an option any more (its file stays)")

## Where it can happen and where it leads; dimmed if it can't happen in the picked stage, marked if it leads into it
func _fill_story_cells(item: TreeItem, option: AdventureEvent) -> void:
	var stages: Array[String] = [ ]
	for track: AdventureStageTrack in _storyline.encounter.tracks:
		if track == null: continue
		var in_track: Array[String] = _storyline.get_stages_in(option, track.name)
		stages.append("%s: %s" % [track.name, " or ".join(in_track)] if not in_track.is_empty() else "%s: any" % track.name)
	var others: String = _storyline.describe_other_conditions(option)
	item.set_text(Column.IN, "  ·  ".join(stages) + ("  ·  when %s" % others if not others.is_empty() else ""))
	item.set_tooltip_text(Column.IN, "Click to change the stages it can happen in")
	var leads: Array[String] = [ ]
	for lead: AdventureStoryline.Lead in _storyline.get_leads(option):
		var what: String = lead.decision.description.get_slice("\n", 0) + (" · " + lead.outcome.name if not lead.outcome.name.is_empty() else "")
		leads.append("%s → %s" % [what, lead.stage])
	item.set_text(Column.LEADS, "\n".join(leads))
	item.set_tooltip_text(Column.LEADS, "Change where decisions lead in the event's pages (double-click)")
	var unknown: Array[String] = _storyline.get_unknown_stages(option)
	if not unknown.is_empty():
		item.set_custom_color(Column.OPTION, UNKNOWN_COLOR)
		item.set_tooltip_text(Column.OPTION, "Not a stage of its track: %s" % ", ".join(unknown))
	if _picked.is_empty(): return
	if not _storyline.can_happen_in(option, _picked[0], _picked[1]):
		for column: int in _tree.columns: item.set_custom_color(column, DIMMED)
	if _storyline.leads_into(option, _picked[0], _picked[1]): item.set_custom_color(Column.LEADS, LEADS_IN_COLOR)

func _on_stage_picked(on: bool, track: String, stage: String) -> void:
	_picked = [track, stage] if on else [ ]
	show_scenario(_scenario, _host)

## A click in the "Happens in" column: the stages to tick
func _on_item_clicked(_position: Vector2, mouse_button: int) -> void:
	if mouse_button != MOUSE_BUTTON_LEFT or _storyline == null or _tree.get_selected_column() != Column.IN: return
	_stage_menu_event = _tree.get_selected().get_metadata(0) as AdventureEvent
	if _stage_menu_event == null: return
	_stage_menu.clear()
	for track: AdventureStageTrack in _storyline.encounter.tracks:
		if track == null: continue
		_stage_menu.add_separator(track.name)
		var in_track: Array[String] = _storyline.get_stages_in(_stage_menu_event, track.name)
		for stage: String in track.stages:
			_stage_menu.add_check_item(stage)
			_stage_menu.set_item_checked(_stage_menu.item_count - 1, in_track.has(stage))
			_stage_menu.set_item_metadata(_stage_menu.item_count - 1, [track.name, stage])
			_stage_menu.set_item_tooltip(_stage_menu.item_count - 1, "None ticked on a track: any of its stages")
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
	if _storyline != null: text_requested.emit("New track", "Name", _add_named_track)

func _add_named_track(track_name: String) -> void:
	_request(_storyline.get_changes_adding_track(track_name), "New track %s" % track_name)

func _ask_for_stage(track: AdventureStageTrack) -> void:
	text_requested.emit("New stage on %s" % track.name, "Name", _add_stage.bind(track))

func _add_stage(stage: String, track: AdventureStageTrack) -> void:
	_request(_storyline.get_changes_adding_stage(track, stage), "New stage %s: %s" % [track.name, stage])

func _on_pick_selected(index: int) -> void:
	var pick: int = _pick.get_item_id(index)
	if pick == _scenario.pick: return
	_request([[_scenario, &"pick", pick, AdventureEventEditing.get_file(_scenario)]] as Array[Array], "%s: %s" % [AdventureGraph.get_title(_scenario), _pick.get_item_text(index)])

func _on_item_selected() -> void:
	var resource: Resource = _tree.get_selected().get_metadata(0) as Resource
	if resource != null: EditorInterface.edit_resource(resource)

func _on_item_activated() -> void:
	var option: AdventureEvent = _tree.get_selected().get_metadata(0) as AdventureEvent
	if option != null: event_opened.emit(option, _host)

func _on_button_clicked(item: TreeItem, _column: int, id: int, _mouse_button: int) -> void:
	var options: Array[AdventureEvent] = _scenario.events.duplicate()
	var index: int = item.get_index()
	var option: AdventureEvent = options.pop_at(index)
	var title: String = AdventureGraph.get_title(option) if option != null else "empty option"
	if id == Act.REMOVE:
		_request(AdventureEventEditing.get_changes_listing(_scenario, options), "Remove %s from %s" % [title, AdventureGraph.get_title(_scenario)])
		return
	options.insert(index + (-1 if id == Act.UP else 1), option)
	_request(AdventureEventEditing.get_changes_listing(_scenario, options), "Move %s" % title)

func _request(changes: Array[Array], action: String) -> void:
	if not changes.is_empty(): changes_requested.emit(changes, action, null)

static func _make_button(text: String, tooltip: String, on_pressed: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.tooltip_text = tooltip
	button.icon = AdventureActionMenu.get_editor_icon("Add")
	button.pressed.connect(on_pressed)
	return button
