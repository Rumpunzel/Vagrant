@tool
class_name AdventureMapView
extends AdventureGraphView

## The adventure's map ([AdventureGraph]): areas as frames around their locations, links through events dashed.
## Edits are only requested here; [AdventureEditor] makes them (undo, saving).

signal link_requested(from: AdventurePage, to: AdventurePage)
signal unlink_requested(from: AdventurePage, to: AdventurePage)
## [param at]: where on the graph
signal location_requested(at: Vector2)
signal event_requested(location: AdventurePage, scenario: bool)
## The new area per moved page; none: no area
signal areas_requested(areas: Dictionary[AdventurePage, AdventureArea])

## Locations let go of their frame during the current drag, with that frame
var _detached: Dictionary[GraphElement, GraphFrame] = {}

func setup() -> void:
	super()
	right_disconnects = true
	connection_request.connect(func(from: StringName, _from_port: int, to: StringName, _to_port: int) -> void: link_requested.emit(_page_of(from), _page_of(to)))
	disconnection_request.connect(func(from: StringName, _from_port: int, to: StringName, _to_port: int) -> void: unlink_requested.emit(_page_of(from), _page_of(to)))
	begin_node_move.connect(_on_move_started)
	end_node_move.connect(_on_moved)
	popup_request.connect(func(at_position: Vector2) -> void:
		var at: Vector2 = _to_graph(at_position)
		_show_menu({"New location here": location_requested.emit.bind(at)})
	)

func show_graph(graph: AdventureGraph) -> void:
	_clear()
	var frames: Dictionary[AdventureArea, GraphFrame] = {}
	for area: AdventureArea in graph.areas: frames[area] = _add_frame(area.name, area, area.background)
	var row_sizes: Dictionary[int, int] = {}
	for page: AdventurePage in graph.pages:
		var row: int = graph.areas.find(page.area) if page.area != null else graph.areas.size()
		var column: int = row_sizes.get(row, 0)
		row_sizes[row] = column + 1
		var node: GraphNode = _add_node(_key(page), page, AdventureGraph.get_title(page), _make_page_content(page), Vector2(column, row) * NODE_SPACING)
		node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
		_on_right_click(node, func() -> Dictionary[String, Callable]: return {
			"New event here": event_requested.emit.bind(page, false),
			"New scenario here": event_requested.emit.bind(page, true),
		})
		if graph.unreachable.has(page):
			node.modulate = FADED
			node.tooltip_text = "Not reached from the starting page"
		if page.area != null: attach_graph_element_to_frame(node.name, frames[page.area].name)
	for link: AdventureGraph.Link in graph.links:
		if link.through_event: _add_dashed(_nodes[_key(link.from)], _nodes[_key(link.to)])
		else: connect_node(_nodes[_key(link.from)].name, 0, _nodes[_key(link.to)].name, 0)

func focus_page(page: AdventurePage) -> void: focus_node(_nodes.get(_key(page)))

func _on_event_card_pressed(event: AdventurePage, page: AdventurePage) -> void: event_opened.emit(event, page)

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
	var areas: Dictionary[AdventurePage, AdventureArea] = {}
	for element: GraphElement in _detached:
		var page: AdventurePage = _resources[element] as AdventurePage
		var area: AdventureArea = _get_area_at(element.position_offset + element.size / 2)
		if area != page.area: areas[page] = area
		else: attach_graph_element_to_frame(element.name, _detached[element].name)
	# Locations without an area are in no frame; dropped into one, they join it
	for element: GraphElement in _resources:
		var page: AdventurePage = _resources[element] as AdventurePage
		if page == null or page.area != null or not element.selected: continue
		var area: AdventureArea = _get_area_at(element.position_offset + element.size / 2)
		if area != null: areas[page] = area
	_detached.clear()
	# Applying rebuilds the graph, which must not happen while it reports the move
	if not areas.is_empty(): areas_requested.emit.call_deferred(areas)

func _get_area_at(point: Vector2) -> AdventureArea:
	for element: GraphElement in _resources:
		if element is GraphFrame and Rect2(element.position_offset, element.size).has_point(point): return _resources[element] as AdventureArea
	return null

func _page_of(node_name: StringName) -> AdventurePage:
	return _resources.get(get_node(NodePath(node_name)) as GraphElement) as AdventurePage

static func _key(page: AdventurePage) -> String: return AdventureLayout.get_key(page)
