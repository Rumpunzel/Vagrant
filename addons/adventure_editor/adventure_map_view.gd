@tool
class_name AdventureMapView
extends AdventureGraphView

## The adventure's map ([AdventureGraph]): areas as frames around their locations, a straight line per linked pair (arrows for the direction, dashed through events).
## Edits are only requested ([signal AdventureGraphView.changes_requested]); [AdventureEditor] makes them (undo, saving).

## [param at]: where on the graph
signal location_requested(at: Vector2)
signal event_requested(location: AdventureLocation, scenario: bool)
## An event already made, to be listed on [param location] too
signal existing_event_requested(location: AdventureLocation)
## Double-clicked: show it in the location tab
signal location_opened(location: AdventureLocation)
## A new encounter that could be at [param location]: an NPC, or (with [param profile], none: ask for one) a monster
signal encounter_requested(location: AdventureLocation, monster: bool, profile: MonsterProfile)

## The texts the map asks for: a decision's or an area's, and their first-time texts
const TEXT_PROPERTIES: Array[StringName] = [&"description", &"first_description"]

## Locations let go of their frame during the current drag, with that frame
var _detached: Dictionary[GraphElement, GraphFrame] = {}
var _texts_dialog: AdventureTextsDialog
var _ambience: AudioStreamPlayer
## The ▶ buttons, with what each plays
var _ambience_buttons: Dictionary[Button, AudioStream] = {}

func setup() -> void:
	super()
	right_disconnects = true
	connection_request.connect(func(from: StringName, _from_port: int, to: StringName, _to_port: int) -> void: _ask_link(_page_of(from), _page_of(to)))
	disconnection_request.connect(func(from: StringName, _from_port: int, to: StringName, _to_port: int) -> void: _unlink(_page_of(from), _page_of(to)))
	_texts_dialog = AdventureTextsDialog.new()
	add_child(_texts_dialog)
	_ambience = AudioStreamPlayer.new()
	add_child(_ambience)
	_ambience.finished.connect(_show_ambience_playing)
	visibility_changed.connect(_on_visibility_changed)
	begin_node_move.connect(_on_move_started)
	end_node_move.connect(_on_moved)
	popup_request.connect(func(at_position: Vector2) -> void:
		var at: Vector2 = _to_graph(at_position)
		_show_menu({"New location here": location_requested.emit.bind(at)})
	)

func _add_frame(title: String, resource: Resource, background_texture: Texture2D) -> GraphFrame:
	var frame: GraphFrame = GraphFrame.new()
	frame.name = "Frame%d" % _resources.size()
	frame.title = title
	frame.autoshrink_margin = FRAME_MARGIN
	if background_texture != null:
		var background: TextureRect = _make_texture_rect(background_texture)
		background.modulate.a = FRAME_BACKGROUND_ALPHA
		frame.add_child(background)
	add_child(frame)
	_resources[frame] = resource
	return frame

func show_graph(graph: AdventureGraph) -> void:
	_clear()
	_ambience_buttons.clear()
	var frames: Dictionary[AdventureArea, GraphFrame] = {}
	for area: AdventureArea in graph.areas:
		frames[area] = _add_frame(area.name, area, area.background)
		_add_ambience_button(frames[area].get_titlebar_hbox(), area.ambience, "Play the area's ambience")
		_on_right_click(frames[area], func() -> Dictionary[String, Callable]: return {"Edit area texts…": _ask_area_texts.bind(area), "Delete area…": deletion_requested.emit.bind(area)})
	var row_sizes: Dictionary[int, int] = {}
	for page: AdventurePage in graph.pages:
		var location: AdventureLocation = page as AdventureLocation
		var area: AdventureArea = location.area if location != null else null
		var row: int = graph.areas.find(area) if area != null else graph.areas.size()
		var column: int = row_sizes.get(row, 0)
		row_sizes[row] = column + 1
		var content: VBoxContainer = _make_page_content(page)
		# Encounters that could show here, faded
		if location != null:
			for encounter: AdventureEncounter in graph.get_encounters_at(location):
				var card: Button = _make_event_card(encounter, page)
				card.text = "%s (could be here)" % AdventureGraph.get_title(encounter)
				card.modulate = FADED
				content.add_child(card)
		content.add_child(_make_exits(graph, page))
		var starts: bool = page == graph.adventure.starting_page
		var node: GraphNode = _add_node(_key(page), page, ("★ " if starts else "") + AdventureGraph.get_title(page), content, Vector2(column, row) * NODE_SPACING)
		node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
		if page.ambience != null: _add_ambience_button(node.get_titlebar_hbox(), page.ambience, "Play its ambience")
		elif area != null: _add_ambience_button(node.get_titlebar_hbox(), area.ambience, "Play its area's ambience")
		_on_right_click(node, func() -> Dictionary[String, Callable]: return _get_location_actions(graph, page))
		if location != null:
			node.gui_input.connect(func(input: InputEvent) -> void:
				var click: InputEventMouseButton = input as InputEventMouseButton
				if click != null and click.double_click: call_after_release(location_opened.emit.bind(location))
			)
		if graph.unreachable.has(page):
			node.modulate = FADED
			node.tooltip_text = "Not reached from the starting page"
		if area != null: attach_graph_element_to_frame(node.name, frames[area].name)
	# One line per pair: GraphEdit's curves leave right and enter left, which loops for links going back or both ways
	var drawn: Array[AdventureGraph.Link] = [ ]
	for link: AdventureGraph.Link in graph.links:
		var back: AdventureGraph.Link = graph.get_link(link.to, link.from)
		if drawn.has(back): continue
		drawn.append(link)
		var arrows: int = ARROW_END | (ARROW_START if back != null else 0)
		var dashed: bool = link.through_event and (back == null or back.through_event)
		_add_line(_nodes[_key(link.from)], _nodes[_key(link.to)], DASHED_COLOR if dashed else LINE_COLOR, dashed, arrows)

## Only locations get events
func _get_location_actions(graph: AdventureGraph, page: AdventurePage) -> Dictionary[String, Callable]:
	var actions: Dictionary[String, Callable] = { }
	if page is AdventureLocation:
		actions["New event here"] = event_requested.emit.bind(page, false)
		actions["New scenario here"] = event_requested.emit.bind(page, true)
		actions["Add event…"] = existing_event_requested.emit.bind(page)
		actions["New encounter here…"] = encounter_requested.emit.bind(page, false, null)
		actions["New monster encounter here…"] = encounter_requested.emit.bind(page, true, null)
	actions["Play from here"] = play_requested.emit.bind(page, null)
	if page != graph.adventure.starting_page:
		actions["Set as starting page"] = _request.bind(graph.adventure, &"starting_page", page, "Start at %s" % AdventureGraph.get_title(page), graph.adventure)
	actions["Delete location…" if page is AdventureLocation else "Delete page…"] = deletion_requested.emit.bind(page)
	for link: AdventureGraph.Link in graph.links:
		if link.from == page and not link.through_event: actions["Unlink from %s" % AdventureGraph.get_title(link.to)] = _unlink.bind(page, link.to)
	return actions

func focus_page(page: AdventurePage) -> void: focus_node(_nodes.get(_key(page)))

func _on_event_card_pressed(event: AdventureEvent, page: AdventurePage) -> void: event_opened.emit(event, page)

func _get_event_card_actions(event: AdventureEvent, page: AdventurePage) -> Dictionary[String, Callable]:
	var encounter: AdventureEncounter = event as AdventureEncounter
	if encounter != null and page is AdventureLocation and encounter.places.has(AdventureLayout.get_key(page)):
		return {"Not here any more (it stays)": set_place.bind(encounter, page, false)}
	if not AdventureGraph.get_listed_on(page).has(event): return {}
	return {"Remove from here (the file stays)": _remove_event.bind(page, event)}

## Whether [param encounter] could be at [param location] (its [member AdventureEncounter.places])
func set_place(encounter: AdventureEncounter, location: AdventureLocation, here: bool) -> void:
	var action: String = ("%s could be at %s" if here else "%s not at %s any more") % [AdventureGraph.get_title(encounter), AdventureGraph.get_title(location)]
	changes_requested.emit(AdventureMapEditing.get_changes_placing(encounter, location, here), action, null)

## Frames grow with their locations; Alt while dragging lets them go, so they can leave
func _on_move_started() -> void:
	_detached.clear()
	if not Input.is_key_pressed(KEY_ALT): return
	for element: GraphElement in _resources:
		var frame: GraphFrame = get_element_frame(element.name)
		if element is GraphNode and element.selected and frame != null:
			_detached[element] = frame
			detach_graph_element_from_frame(element.name)

## A location let go of gets the area of the frame under its center (none outside all frames); dropped back on its own, it is attached again
func _on_moved() -> void:
	var changes: Array[Array] = [ ]
	for element: GraphElement in _detached:
		var location: AdventureLocation = _resources[element] as AdventureLocation
		var area: AdventureArea = _get_area_at(element.position_offset + element.size / 2)
		if location != null and area != location.area: changes.append([location, &"area", area])
		else: attach_graph_element_to_frame(element.name, _detached[element].name)
	# Locations without an area are in no frame; dropped into one, they join it
	for element: GraphElement in _resources:
		var location: AdventureLocation = _resources[element] as AdventureLocation
		if location == null or location.area != null or not element.selected: continue
		var area: AdventureArea = _get_area_at(element.position_offset + element.size / 2)
		if area != null: changes.append([location, &"area", area])
	_detached.clear()
	# Applying rebuilds the graph, which must not happen while it reports the move
	if not changes.is_empty(): changes_requested.emit.call_deferred(changes, "Change area", null)

## Events from the sidebar or the FileSystem panel onto a location; images onto a location or an area's frame
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var at: Vector2 = _to_graph(at_position)
	if data is Dictionary and (data as Dictionary).has("adventure_event"): return _get_page_at(at) is AdventureLocation
	for path: String in _get_dropped_files(data):
		if _is_image(path) and (_get_page_at(at) != null or _get_area_at(at) != null): return true
		if path.get_extension() == "tres" and _get_page_at(at) is AdventureLocation: return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var at: Vector2 = _to_graph(at_position)
	var page: AdventurePage = _get_page_at(at)
	var location: AdventureLocation = page as AdventureLocation
	if data is Dictionary and (data as Dictionary).has("adventure_event"):
		put_event(location, (data as Dictionary)["adventure_event"] as AdventureEvent)
		return
	for path: String in _get_dropped_files(data):
		var dropped: Resource = load(path)
		if dropped is Texture2D:
			var target: Resource = page if page != null else _get_area_at(at)
			if target != null: _request(target, &"background", dropped, "Set background", target)
		elif dropped is AdventureEvent and location != null: put_event(location, dropped as AdventureEvent)
		elif dropped is MonsterProfile and location != null: encounter_requested.emit(location, true, dropped as MonsterProfile)
		else: push_warning("%s is no image, event, encounter or monster" % path)


## [param event] at [param location] too: an encounter could be there, another event is listed there
func put_event(location: AdventureLocation, event: AdventureEvent) -> void:
	var changes: Array[Array] = AdventureMapEditing.get_changes_putting(location, event)
	if changes.is_empty(): push_warning("%s is on %s already" % [AdventureGraph.get_title(event), AdventureGraph.get_title(location)])
	else: changes_requested.emit(changes, "Add %s to %s" % [AdventureGraph.get_title(event), AdventureGraph.get_title(location)], null)

## Refused for events stored inside the location's file, which would be lost
func _remove_event(location: AdventureLocation, event: AdventureEvent) -> void:
	if AdventureEventEditing.is_inside_file(event):
		push_warning("%s is stored inside %s's file and would be lost" % [AdventureGraph.get_title(event), AdventureGraph.get_title(location)])
		return
	changes_requested.emit(AdventureMapEditing.get_changes_removing(location, event), "Remove %s from %s" % [AdventureGraph.get_title(event), AdventureGraph.get_title(location)], null)

## Asks for the new decision's texts first
func _ask_link(from: AdventurePage, to: AdventurePage) -> void:
	if from == null or to == null or from == to: return
	# Already linked: dragging the same link again would offer it twice
	if AdventureMapEditing.without_links(from, to).size() != from.decisions.size(): return
	var title: String = "Link %s to %s" % [AdventureGraph.get_title(from), AdventureGraph.get_title(to)]
	_texts_dialog.ask(title, _get_exit_fields(AdventureMakers.make_link(to), to), _link.bind(from, to, title))

func _link(texts: Array[String], from: AdventurePage, to: AdventurePage, title: String) -> void:
	var link: AdventureDecision = AdventureMakers.make_link(to)
	if not texts[0].is_empty(): link.description = texts[0]
	link.first_description = texts[1]
	var decisions: Array[AdventureDecision] = from.decisions.duplicate()
	decisions.append(link)
	_request(from, &"decisions", decisions, title, from)

## [param page]'s own plain decisions leading to pages on the map, a row each: click to change its texts; the way back is offered where there is none
func _make_exits(graph: AdventureGraph, page: AdventurePage) -> VBoxContainer:
	var exits: VBoxContainer = VBoxContainer.new()
	exits.add_theme_constant_override(&"separation", 0)
	for decision: AdventureDecision in page.decisions:
		if decision == null or decision is AdventureDiceDecision or decision.transition == null: continue
		var to: AdventurePage = decision.transition.get_adventure_page()
		if to == null or not graph.pages.has(to): continue
		var row: HBoxContainer = HBoxContainer.new()
		var exit: Button = Button.new()
		exit.flat = true
		exit.alignment = HORIZONTAL_ALIGNMENT_LEFT
		exit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		exit.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		exit.text = "→ %s: %s" % [AdventureGraph.get_title(to), decision.description.get_slice("\n", 0)]
		exit.tooltip_text = decision.description
		if not decision.first_description.is_empty(): exit.tooltip_text += "\nThe first time: %s" % decision.first_description
		exit.tooltip_text += "\nClick to change"
		exit.pressed.connect(_ask_exit_texts.bind(page, decision, to))
		row.add_child(exit)
		if graph.get_link(to, page) == null:
			row.add_child(_make_tool_button("Back", "+ back", "No way back from %s; click to add one" % AdventureGraph.get_title(to), _ask_link.bind(to, page)))
		exits.add_child(row)
		if not decision.first_description.is_empty():
			var first: Label = _make_info("   the first time: %s" % decision.first_description.get_slice("\n", 0))
			first.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			exits.add_child(first)
	return exits

func _get_exit_fields(decision: AdventureDecision, to: AdventurePage) -> Array[AdventureTextsDialog.Field]:
	return [
		AdventureTextsDialog.Field.new("Text", decision.description),
		AdventureTextsDialog.Field.new("The first time (until %s was visited)" % AdventureGraph.get_title(to), decision.first_description, "None: always the text above"),
	]

func _ask_exit_texts(page: AdventurePage, decision: AdventureDecision, to: AdventurePage) -> void:
	var title: String = "%s → %s" % [AdventureGraph.get_title(page), AdventureGraph.get_title(to)]
	_texts_dialog.ask(title, _get_exit_fields(decision, to), _set_texts.bind(decision, TEXT_PROPERTIES, title, page))

func _ask_area_texts(area: AdventureArea) -> void:
	var fields: Array[AdventureTextsDialog.Field] = [
		AdventureTextsDialog.Field.new("On entering it from another area", area.description, "None", true),
		AdventureTextsDialog.Field.new("The first time", area.first_description, "None: the text above", true),
	]
	var title: String = "%s's texts" % area.name
	_texts_dialog.ask(title, fields, _set_texts.bind(area, TEXT_PROPERTIES, title, area))

## A decision's text can't be emptied; the others can
func _set_texts(texts: Array[String], resource: Resource, properties: Array[StringName], action: String, file: Resource) -> void:
	var changes: Array[Array] = [ ]
	for index: int in properties.size():
		var text: String = texts[index]
		var now: String = resource.get(properties[index])
		if text == now or (text.is_empty() and resource is AdventureDecision and properties[index] == &"description"): continue
		changes.append([resource, properties[index], text])
	if not changes.is_empty(): changes_requested.emit(changes, action, file)

## A ▶ in [param bar] (none without [param stream]); one ambience plays at a time
func _add_ambience_button(bar: HBoxContainer, stream: AudioStream, tooltip: String) -> void:
	if stream == null: return
	var button: Button = Button.new()
	button.flat = true
	button.toggle_mode = true
	button.icon = _get_editor_icon("AudioStreamPlayer")
	if button.icon == null: button.text = "▶"
	button.tooltip_text = tooltip
	button.set_pressed_no_signal(_ambience.playing and _ambience.stream == stream)
	button.toggled.connect(_toggle_ambience.bind(stream))
	bar.add_child(button)
	_ambience_buttons[button] = stream

func _toggle_ambience(on: bool, stream: AudioStream) -> void:
	if on:
		_ambience.stream = stream
		_ambience.play()
	elif _ambience.stream == stream: _ambience.stop()
	_show_ambience_playing()

func _show_ambience_playing() -> void:
	for button: Button in _ambience_buttons: button.set_pressed_no_signal(_ambience.playing and _ambience.stream == _ambience_buttons[button])

func _on_visibility_changed() -> void:
	if is_visible_in_tree(): return
	_ambience.stop()
	_show_ambience_playing()

## Removes the plain decisions leading there; fights and saves stay
func _unlink(from: AdventurePage, to: AdventurePage) -> void:
	if from == null or to == null: return
	var decisions: Array[AdventureDecision] = AdventureMapEditing.without_links(from, to)
	if decisions.size() == from.decisions.size():
		push_warning("%s leads to %s only through a fight or save; change it in the events tab or the Inspector" % [AdventureGraph.get_title(from), AdventureGraph.get_title(to)])
		return
	_request(from, &"decisions", decisions, "Unlink %s from %s" % [AdventureGraph.get_title(from), AdventureGraph.get_title(to)], from)

func _get_area_at(point: Vector2) -> AdventureArea:
	for element: GraphElement in _resources:
		if element is GraphFrame and Rect2(element.position_offset, element.size).has_point(point): return _resources[element] as AdventureArea
	return null

func _page_of(node_name: StringName) -> AdventurePage:
	return _resources.get(get_node(NodePath(node_name)) as GraphElement) as AdventurePage

static func _key(page: AdventurePage) -> String: return AdventureLayout.get_key(page)
