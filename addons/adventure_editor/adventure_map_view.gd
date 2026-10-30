@tool
class_name AdventureMapView
extends AdventureGraphView

## The adventure's map ([AdventureGraph]): areas as frames around their locations, a straight line per linked pair (arrows for the direction, dashed through events).
## Edits are only requested ([signal AdventureGraphView.changes_requested]); [AdventureEditor] makes them (undo, saving).

## [param at]: where on the graph
signal location_requested(at: Vector2)
signal event_requested(location: AdventurePage, scenario: bool)
## An event already made, to be listed on [param location] too
signal existing_event_requested(location: AdventurePage)

## Locations let go of their frame during the current drag, with that frame
var _detached: Dictionary[GraphElement, GraphFrame] = {}

func setup() -> void:
	super()
	right_disconnects = true
	connection_request.connect(func(from: StringName, _from_port: int, to: StringName, _to_port: int) -> void: _link(_page_of(from), _page_of(to)))
	disconnection_request.connect(func(from: StringName, _from_port: int, to: StringName, _to_port: int) -> void: _unlink(_page_of(from), _page_of(to)))
	begin_node_move.connect(_on_move_started)
	end_node_move.connect(_on_moved)
	popup_request.connect(func(at_position: Vector2) -> void:
		var at: Vector2 = _to_graph(at_position)
		_show_menu({"New location here": location_requested.emit.bind(at)})
	)

func show_graph(graph: AdventureGraph) -> void:
	_clear()
	var frames: Dictionary[AdventureArea, GraphFrame] = {}
	for area: AdventureArea in graph.areas:
		frames[area] = _add_frame(area.name, area, area.background)
		_on_right_click(frames[area], func() -> Dictionary[String, Callable]: return {"Delete area…": deletion_requested.emit.bind(area)})
	var row_sizes: Dictionary[int, int] = {}
	for page: AdventurePage in graph.pages:
		var row: int = graph.areas.find(page.area) if page.area != null else graph.areas.size()
		var column: int = row_sizes.get(row, 0)
		row_sizes[row] = column + 1
		var content: VBoxContainer = _make_page_content(page)
		# Nearby events of the events around, faded, with where they come from
		for nearby: Array in page.find_nearby_events():
			var card: Button = _make_event_card(nearby[0], page)
			card.text = "%s · from %s" % [AdventureGraph.get_title(nearby[0]), AdventureGraph.get_title(nearby[1])]
			card.modulate = FADED
			content.add_child(card)
		var node: GraphNode = _add_node(_key(page), page, AdventureGraph.get_title(page), content, Vector2(column, row) * NODE_SPACING)
		node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
		_on_right_click(node, func() -> Dictionary[String, Callable]: return _get_location_actions(graph, page))
		if graph.unreachable.has(page):
			node.modulate = FADED
			node.tooltip_text = "Not reached from the starting page"
		if page.area != null: attach_graph_element_to_frame(node.name, frames[page.area].name)
	# One line per pair: GraphEdit's curves leave right and enter left, which loops for links going back or both ways
	var drawn: Array[AdventureGraph.Link] = [ ]
	for link: AdventureGraph.Link in graph.links:
		var back: AdventureGraph.Link = graph.get_link(link.to, link.from)
		if drawn.has(back): continue
		drawn.append(link)
		var arrows: int = ARROW_END | (ARROW_START if back != null else 0)
		var dashed: bool = link.through_event and (back == null or back.through_event)
		_add_line(_nodes[_key(link.from)], _nodes[_key(link.to)], DASHED_COLOR if dashed else LINE_COLOR, dashed, arrows)

func _get_location_actions(graph: AdventureGraph, page: AdventurePage) -> Dictionary[String, Callable]:
	var actions: Dictionary[String, Callable] = {
		"New event here": event_requested.emit.bind(page, false),
		"New scenario here": event_requested.emit.bind(page, true),
		"Add event…": existing_event_requested.emit.bind(page),
		"Play from here": play_requested.emit.bind(page, null),
		"Delete location…": deletion_requested.emit.bind(page),
	}
	for link: AdventureGraph.Link in graph.links:
		if link.from == page and not link.through_event: actions["Unlink from %s" % AdventureGraph.get_title(link.to)] = _unlink.bind(page, link.to)
	return actions

func focus_page(page: AdventurePage) -> void: focus_node(_nodes.get(_key(page)))

func _on_event_card_pressed(event: AdventurePage, page: AdventurePage) -> void: event_opened.emit(event, page)

func _get_event_card_actions(event: AdventurePage, page: AdventurePage) -> Dictionary[String, Callable]:
	if not page.events.has(event): return {}
	return {"Remove from here (the file stays)": _remove_event.bind(page, event)}

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
		var page: AdventurePage = _resources[element] as AdventurePage
		var area: AdventureArea = _get_area_at(element.position_offset + element.size / 2)
		if area != page.area: changes.append([page, &"area", area])
		else: attach_graph_element_to_frame(element.name, _detached[element].name)
	# Locations without an area are in no frame; dropped into one, they join it
	for element: GraphElement in _resources:
		var page: AdventurePage = _resources[element] as AdventurePage
		if page == null or page.area != null or not element.selected: continue
		var area: AdventureArea = _get_area_at(element.position_offset + element.size / 2)
		if area != null: changes.append([page, &"area", area])
	_detached.clear()
	# Applying rebuilds the graph, which must not happen while it reports the move
	if not changes.is_empty(): changes_requested.emit.call_deferred(changes, "Change area", null)

## Events from the sidebar or the FileSystem panel onto a location; images onto a location or an area's frame
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var at: Vector2 = _to_graph(at_position)
	if data is Dictionary and (data as Dictionary).has("adventure_event"): return _get_page_at(at) != null
	for path: String in _get_dropped_files(data):
		if _is_image(path) and (_get_page_at(at) != null or _get_area_at(at) != null): return true
		if path.get_extension() == "tres" and _get_page_at(at) != null: return true
	return false

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var at: Vector2 = _to_graph(at_position)
	var location: AdventurePage = _get_page_at(at)
	if data is Dictionary and (data as Dictionary).has("adventure_event"):
		add_event(location, (data as Dictionary)["adventure_event"])
		return
	for path: String in _get_dropped_files(data):
		var dropped: Resource = load(path)
		if dropped is Texture2D:
			var target: Resource = location if location != null else _get_area_at(at)
			if target != null: _request(target, &"background", dropped, "Set background", target)
		elif dropped is AdventurePage and location != null: add_event(location, dropped as AdventurePage)
		else: push_warning("%s is no image or event" % path)

## Lists [param event] on [param location] too
func add_event(location: AdventurePage, event: AdventurePage) -> void:
	if location.events.has(event):
		push_warning("%s is on %s already" % [AdventureGraph.get_title(event), AdventureGraph.get_title(location)])
		return
	var events: Array[AdventurePage] = location.events.duplicate()
	events.append(event)
	_request(location, &"events", events, "Add %s to %s" % [AdventureGraph.get_title(event), AdventureGraph.get_title(location)], location)

## Refused for events stored inside the location's file, which would be lost
func _remove_event(location: AdventurePage, event: AdventurePage) -> void:
	if AdventureEventEditing.is_inside_file(event):
		push_warning("%s is stored inside %s's file and would be lost" % [AdventureGraph.get_title(event), AdventureGraph.get_title(location)])
		return
	var events: Array[AdventurePage] = location.events.duplicate()
	events.erase(event)
	_request(location, &"events", events, "Remove %s from %s" % [AdventureGraph.get_title(event), AdventureGraph.get_title(location)], location)

func _link(from: AdventurePage, to: AdventurePage) -> void:
	if from == null or to == null or from == to: return
	var decisions: Array[AdventureDecision] = from.decisions.duplicate()
	decisions.append(AdventureMapEditing.make_link(to))
	_request(from, &"decisions", decisions, "Link %s to %s" % [AdventureGraph.get_title(from), AdventureGraph.get_title(to)], from)

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
