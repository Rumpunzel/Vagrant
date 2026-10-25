@tool
class_name AdventureMapView
extends AdventureGraphView

## The adventure's map ([AdventureGraph]): areas as frames around their locations, links through events dashed

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
		if page.area != null: attach_graph_element_to_frame(node.name, frames[page.area].name)
	for link: AdventureGraph.Link in graph.links:
		if link.through_event: _add_dashed(_nodes[_key(link.from)], _nodes[_key(link.to)])
		else: connect_node(_nodes[_key(link.from)].name, 0, _nodes[_key(link.to)].name, 0)

func focus_page(page: AdventurePage) -> void: focus_node(_nodes.get(_key(page)))

func _on_event_card_pressed(event: AdventurePage, page: AdventurePage) -> void: event_opened.emit(event, page)

static func _key(page: AdventurePage) -> String: return AdventureLayout.get_key(page)
