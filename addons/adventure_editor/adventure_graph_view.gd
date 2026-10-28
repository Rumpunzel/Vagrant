@tool
@abstract
class_name AdventureGraphView
extends GraphEdit

## Shared by the adventure editor's graphs: page nodes (background, event cards), frames, dashed links, selection to the Inspector, positions in the [AdventureLayout]

## [param host]: the page whose card was clicked, if any
signal event_opened(event: AdventurePage, host: AdventurePage)
## Nodes moved; their positions are in [member layout] already
signal layout_changed

const NODE_SPACING: Vector2 = Vector2(280, 240)
const THUMBNAIL_SIZE: Vector2 = Vector2(220, 124)
## Room for a frame's title and the menu when scrolling to the nodes
const SCROLL_MARGIN: Vector2 = Vector2(80, 160)
const FRAME_MARGIN: int = 64
const FRAME_BACKGROUND_ALPHA: float = 0.35
const DASHED_COLOR: Color = Color(1, 1, 1, 0.6)
const FADED: Color = Color(1, 1, 1, 0.5)

var layout: AdventureLayout

## By layout key
var _nodes: Dictionary[String, GraphNode] = {}
var _resources: Dictionary[GraphElement, Resource] = {}
## [from, to] node pairs, drawn dashed
var _dashed: Array[Array] = [ ]
var _dashed_layer: Control
var _menu: PopupMenu
## Item text -> what it does, for the open menu
var _menu_actions: Dictionary[String, Callable] = {}

## Called by [AdventureEditor], not in [method Node._ready], so opening the scene in the editor doesn't run it
func setup() -> void:
	node_selected.connect(_on_node_selected)
	end_node_move.connect(_on_end_node_move)
	_add_dashed_layer()
	_menu = PopupMenu.new()
	_menu.index_pressed.connect(func(index: int) -> void: _menu_actions[_menu.get_item_text(index)].call())
	add_child(_menu, false, Node.INTERNAL_MODE_FRONT)
	scroll_offset_changed.connect(func(_offset: Vector2) -> void: _dashed_layer.queue_redraw())

## Puts the top left node near the top left corner
func scroll_to_nodes() -> void:
	if _nodes.is_empty(): return
	var top_left: Vector2 = Vector2.INF
	for node: GraphNode in _nodes.values(): top_left = top_left.min(node.position_offset)
	scroll_offset = (top_left - SCROLL_MARGIN) * zoom

## Shows the node in the middle and selects it
func focus_node(node: GraphNode) -> void:
	if node == null: return
	set_selected(node)
	scroll_offset = (node.position_offset + node.size / 2) * zoom - size / 2

@abstract func _on_event_card_pressed(event: AdventurePage, page: AdventurePage) -> void

## A context menu at the mouse: item text -> what it does (and its icon, if any)
func _show_menu(actions: Dictionary[String, Callable], icons: Dictionary[String, Texture2D] = {}) -> void:
	_menu_actions = actions
	_menu.clear()
	for text: String in actions:
		if icons.get(text) != null: _menu.add_icon_item(icons[text], text)
		else: _menu.add_item(text)
		_menu.set_item_icon_max_width(_menu.item_count - 1, 16)
	_menu.position = DisplayServer.mouse_get_position()
	_menu.reset_size()
	_menu.popup()

## [param pick] gets the actions when [param node] is right-clicked
func _on_right_click(node: GraphNode, pick: Callable, icons: Dictionary[String, Texture2D] = {}) -> void:
	node.gui_input.connect(func(input: InputEvent) -> void:
		var click: InputEventMouseButton = input as InputEventMouseButton
		if click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
			_show_menu(pick.call(), icons)
			accept_event()
	)

## Where [param at_position] (in this control) is on the graph
func _to_graph(at_position: Vector2) -> Vector2: return (scroll_offset + at_position) / zoom

func _clear() -> void:
	clear_connections()
	for element: GraphElement in _resources:
		remove_child(element)
		element.queue_free()
	_nodes.clear()
	_resources.clear()
	_dashed.clear()
	_dashed_layer.queue_redraw()

func _add_node(key: String, resource: Resource, title: String, content: Control, default_position: Vector2) -> GraphNode:
	var node: GraphNode = GraphNode.new()
	node.name = "Node%d" % _resources.size()
	node.title = title
	node.add_child(content)
	node.position_offset = layout.positions.get(key, default_position) if layout != null else default_position
	node.position_offset_changed.connect(_dashed_layer.queue_redraw)
	node.resized.connect(_dashed_layer.queue_redraw)
	add_child(node)
	_nodes[key] = node
	_resources[node] = resource
	return node

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

func _add_dashed(from: GraphNode, to: GraphNode) -> void:
	_dashed.append([from, to])
	_dashed_layer.queue_redraw.call_deferred()

## Background thumbnail and a card per event of [param page]
func _make_page_content(page: AdventurePage) -> VBoxContainer:
	var content: VBoxContainer = VBoxContainer.new()
	content.custom_minimum_size.x = THUMBNAIL_SIZE.x
	# Right-clicks reach the node
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	if page.background != null:
		var thumbnail: TextureRect = _make_texture_rect(page.background)
		thumbnail.custom_minimum_size = THUMBNAIL_SIZE
		content.add_child(thumbnail)
	for event: AdventurePage in page.events: content.add_child(_make_event_card(event, page))
	return content

func _make_event_card(event: AdventurePage, page: AdventurePage) -> Button:
	var card: Button = Button.new()
	card.text = AdventureGraph.get_title(event)
	card.tooltip_text = "%s: %s" % ["Scenario" if event is AdventureEventScenario else "Event", event.resource_path]
	card.pressed.connect(_on_event_card_pressed.bind(event, page))
	return card

func _make_texture_rect(texture: Texture2D) -> TextureRect:
	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.texture = texture
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return texture_rect

func _make_label(text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Wrapping labels need a width, or they grow as tall as one word per line
	label.custom_minimum_size.x = THUMBNAIL_SIZE.x
	return label

## A node's info line, faded
func _make_info(text: String) -> Label:
	var label: Label = _make_label(text)
	label.modulate = FADED
	return label

## A page's whole text, with its BBCode
func _make_text(text: String) -> RichTextLabel:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.text = text
	label.custom_minimum_size.x = THUMBNAIL_SIZE.x
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _on_node_selected(element: Node) -> void:
	var resource: Resource = _resources.get(element as GraphElement)
	if resource != null: EditorInterface.edit_resource(resource)

func _on_end_node_move() -> void:
	if layout == null: return
	for key: String in _nodes: layout.positions[key] = _nodes[key].position_offset
	layout_changed.emit()

## Dashed links: GraphEdit's connections can't be dashed; drawn above the frames, which would hide them
func _add_dashed_layer() -> void:
	_dashed_layer = Control.new()
	_dashed_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dashed_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dashed_layer.draw.connect(_draw_dashed)
	add_child(_dashed_layer, false, Node.INTERNAL_MODE_FRONT)

func _draw_dashed() -> void:
	var to_local: Transform2D = _dashed_layer.get_global_transform().affine_inverse()
	for pair: Array in _dashed:
		var from: Rect2 = (pair[0] as GraphNode).get_global_rect()
		var to: Rect2 = (pair[1] as GraphNode).get_global_rect()
		var start: Vector2 = to_local * Vector2(from.end.x, from.get_center().y)
		var end: Vector2 = to_local * Vector2(to.position.x, to.get_center().y)
		_dashed_layer.draw_dashed_line(start, end, DASHED_COLOR, 2.0 * zoom, 10.0 * zoom)
