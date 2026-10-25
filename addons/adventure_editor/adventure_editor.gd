@tool
class_name AdventureEditor
extends GraphEdit

## Main screen of the adventure editor plugin: the map of one adventure ([AdventureGraph]), areas as frames, pages as nodes, events as cards on their hosts.
## Only views for now: selecting opens the resource in the Inspector, moving nodes saves the [AdventureLayout].

const NODE_SPACING: Vector2 = Vector2(280, 240)
const THUMBNAIL_SIZE: Vector2 = Vector2(220, 124)
const AREA_BACKGROUND_ALPHA: float = 0.35
const EVENT_LINK_COLOR: Color = Color(1, 1, 1, 0.6)
const FRAME_MARGIN: Vector2 = Vector2(80, 120)

var adventure: Adventure : set = set_adventure

var _graph: AdventureGraph
var _layout: AdventureLayout
var _picker: EditorResourcePicker
var _nodes: Dictionary[AdventurePage, GraphNode] = {}
var _resources: Dictionary[GraphElement, Resource] = {}
var _event_links: Control

## Called by the plugin, not in [method Node._ready], so opening this scene in the editor doesn't run it
func setup() -> void:
	_add_event_links_layer()
	_picker = EditorResourcePicker.new()
	_picker.base_type = "Adventure"
	_picker.custom_minimum_size.x = 240
	_picker.resource_changed.connect(func(resource: Resource) -> void: set_adventure(resource as Adventure))
	get_menu_hbox().add_child(_picker)
	node_selected.connect(_on_node_selected)
	end_node_move.connect(_save_layout)
	scroll_offset_changed.connect(func(_offset: Vector2) -> void: _event_links.queue_redraw())
	EditorInterface.get_inspector().property_edited.connect(_on_property_edited)

func set_adventure(value: Adventure) -> void:
	adventure = value
	if _picker != null: _picker.edited_resource = value
	_layout = AdventureLayout.load_for(value) if value != null else null
	rebuild()
	_scroll_to_pages()

## Puts the top left page near the top left corner, leaving room for its frame's title and the menu
func _scroll_to_pages() -> void:
	if _nodes.is_empty(): return
	var top_left: Vector2 = Vector2.INF
	for node: GraphNode in _nodes.values(): top_left = top_left.min(node.position_offset)
	scroll_offset = (top_left - FRAME_MARGIN) * zoom

func rebuild() -> void:
	clear_connections()
	for element: GraphElement in _resources:
		remove_child(element)
		element.queue_free()
	_nodes.clear()
	_resources.clear()
	_graph = AdventureGraph.new(adventure)
	var frames: Dictionary[AdventureArea, GraphFrame] = {}
	for area: AdventureArea in _graph.areas: frames[area] = _add_frame(area)
	var row_sizes: Dictionary[int, int] = {}
	for page: AdventurePage in _graph.pages:
		var node: GraphNode = _add_node(page)
		var area: AdventureArea = page.area
		var row: int = _graph.areas.find(area) if area != null else _graph.areas.size()
		var column: int = row_sizes.get(row, 0)
		row_sizes[row] = column + 1
		node.position_offset = _layout.positions.get(AdventureLayout.get_key(page), Vector2(column, row) * NODE_SPACING)
		if area != null: attach_graph_element_to_frame(node.name, frames[area].name)
	for link: AdventureGraph.Link in _graph.links:
		if not link.through_event: connect_node(_nodes[link.from].name, 0, _nodes[link.to].name, 0)
	_event_links.queue_redraw.call_deferred()

func _add_frame(area: AdventureArea) -> GraphFrame:
	var frame: GraphFrame = GraphFrame.new()
	frame.name = "Area%d" % _resources.size()
	frame.title = area.name
	frame.autoshrink_enabled = true
	if area.background != null:
		var background: TextureRect = _make_texture_rect(area.background)
		background.modulate.a = AREA_BACKGROUND_ALPHA
		frame.add_child(background)
	add_child(frame)
	_resources[frame] = area
	return frame

func _add_node(page: AdventurePage) -> GraphNode:
	var node: GraphNode = GraphNode.new()
	node.name = "Page%d" % _resources.size()
	node.title = AdventureGraph.get_title(page)
	var content: VBoxContainer = VBoxContainer.new()
	content.custom_minimum_size.x = THUMBNAIL_SIZE.x
	if page.background != null:
		var thumbnail: TextureRect = _make_texture_rect(page.background)
		thumbnail.custom_minimum_size = THUMBNAIL_SIZE
		content.add_child(thumbnail)
	for event: AdventurePage in page.events: content.add_child(_make_event_card(event))
	node.add_child(content)
	node.set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	node.position_offset_changed.connect(_event_links.queue_redraw)
	add_child(node)
	_nodes[page] = node
	_resources[node] = page
	return node

func _make_event_card(event: AdventurePage) -> Button:
	var card: Button = Button.new()
	card.text = AdventureGraph.get_title(event)
	card.tooltip_text = "Event: %s" % event.resource_path
	card.pressed.connect(func() -> void: EditorInterface.edit_resource(event))
	return card

func _make_texture_rect(texture: Texture2D) -> TextureRect:
	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.texture = texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return texture_rect

func _on_node_selected(element: Node) -> void:
	var resource: Resource = _resources.get(element as GraphElement)
	if resource != null: EditorInterface.edit_resource(resource)

func _on_property_edited(_property: String) -> void: rebuild()

func _save_layout() -> void:
	if adventure == null: return
	for page: AdventurePage in _nodes: _layout.positions[AdventureLayout.get_key(page)] = _nodes[page].position_offset
	_layout.save_for(adventure)

## Links through events are dashed, which GraphEdit's connections can't be; drawn above the frames, which would hide them
func _add_event_links_layer() -> void:
	_event_links = Control.new()
	_event_links.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_event_links.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_event_links.draw.connect(_draw_event_links)
	add_child(_event_links, false, Node.INTERNAL_MODE_FRONT)

func _draw_event_links() -> void:
	var to_local: Transform2D = _event_links.get_global_transform().affine_inverse()
	for link: AdventureGraph.Link in _graph.links:
		if not link.through_event: continue
		var from: GraphNode = _nodes[link.from]
		var to: GraphNode = _nodes[link.to]
		var start: Vector2 = to_local * from.get_global_transform() * from.get_output_port_position(0)
		var end: Vector2 = to_local * to.get_global_transform() * to.get_input_port_position(0)
		_event_links.draw_dashed_line(start, end, EVENT_LINK_COLOR, 2.0 * zoom, 10.0 * zoom)
