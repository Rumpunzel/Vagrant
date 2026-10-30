@tool
@abstract
class_name AdventureGraphView
extends GraphEdit

## Shared by the adventure editor's graphs: page nodes (background, event cards), frames, dashed links, selection to the Inspector, positions in the [AdventureLayout]

## [param host]: the page whose card was clicked, if any
signal event_opened(event: AdventurePage, host: AdventurePage)
## Nodes moved; their positions are in [member layout] already
signal layout_changed
## Start the game at [param page]; [param event]: the event it is part of, none for a location
signal play_requested(page: AdventurePage, event: AdventurePage)
## Its nodes' positions were forgotten; showing it again puts them back in their default places
signal tidied
## A location, event or area to delete: what points at it goes, its file to the trash ([AdventureEditor] asks first)
signal deletion_requested(resource: Resource)
## [resource, property, value] changes as one undo step called [param action] ([method AdventureEdits.apply]);
## [param file]: the file they are stored in (none: each resource is a file of its own)
signal changes_requested(changes: Array[Array], action: String, file: Resource)

const NODE_SPACING: Vector2 = Vector2(280, 240)
const THUMBNAIL_SIZE: Vector2 = Vector2(220, 124)
## Room for a frame's title and the menu when scrolling to the nodes
const SCROLL_MARGIN: Vector2 = Vector2(80, 160)
const FRAME_MARGIN: int = 64
const FRAME_BACKGROUND_ALPHA: float = 0.35
const DASHED_COLOR: Color = Color(1, 1, 1, 0.6)
const FADED: Color = Color(1, 1, 1, 0.5)
const LINE_COLOR: Color = Color(1, 1, 1, 0.8)
const PROBLEM_COLOR: Color = Color(1, 0.55, 0.5)
const IMAGE_EXTENSIONS: Array[String] = ["png", "jpg", "jpeg", "webp", "svg"]
const ARROW_END: int = 1
const ARROW_START: int = 2
const ARROW_SIZE: float = 12.0
const ICON_SIZE: int = 16
## [words, editor icon] for menu items, the first that fits
const MENU_ICONS: Array[Array] = [
	[["play"], "Play"], [["unlink"], "Unlinked"], [["remove", "delete", "not nearby"], "Remove"], [["other file"], "Load"],
	[["(scenario)"], "GraphEdit"], [["new ", "add "], "Add"],
]

var layout: AdventureLayout
## Shown on the nodes of their pages
var problems: Array[AdventureProblems.Problem] = [ ]

## By layout key
var _nodes: Dictionary[String, GraphNode] = {}
var _resources: Dictionary[GraphElement, Resource] = {}
## [from, to, color, dashed, arrows] lines drawn above everything ([member ARROW_END], [member ARROW_START])
var _dashed: Array[Array] = [ ]
var _dashed_layer: Control
var _menu: PopupMenu
## Item text -> what it does, for the open menu
var _menu_actions: Dictionary[String, Callable] = {}

## Called by [AdventureEditor], not in [method Node._ready], so opening the scene in the editor doesn't run it
func setup() -> void:
	node_selected.connect(_on_node_selected)
	delete_nodes_request.connect(_on_delete_nodes)
	end_node_move.connect(_on_end_node_move)
	_add_dashed_layer()
	_menu = PopupMenu.new()
	_menu.index_pressed.connect(func(index: int) -> void: _menu_actions[_menu.get_item_text(index)].call())
	add_child(_menu, false, Node.INTERNAL_MODE_FRONT)
	scroll_offset_changed.connect(func(_offset: Vector2) -> void: _dashed_layer.queue_redraw())
	_add_tidy_button()

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

## Shows the node of [param resource] in the middle and selects it, if there is one
func focus_resource(resource: Resource) -> void:
	for element: GraphElement in _resources:
		if _resources[element] == resource and element is GraphNode:
			focus_node(element as GraphNode)
			return

@abstract func _on_event_card_pressed(event: AdventurePage, page: AdventurePage) -> void

## What right-clicking [param event]'s card on [param page] offers
func _get_event_card_actions(_event: AdventurePage, _page: AdventurePage) -> Dictionary[String, Callable]: return {}

## A context menu at the mouse, for [AdventureEditor]
func show_actions(actions: Dictionary[String, Callable]) -> void: _show_menu(actions)

## A context menu at the mouse: item text -> what it does; each item gets an icon by what it does ([method _get_menu_icon])
func _show_menu(actions: Dictionary[String, Callable]) -> void:
	_menu_actions = actions
	_menu.clear()
	for text: String in actions:
		var icon: Texture2D = _get_menu_icon(text)
		if icon != null: _menu.add_icon_item(icon, text)
		else: _menu.add_item(text)
		_menu.set_item_icon_max_width(_menu.item_count - 1, ICON_SIZE)
	_menu.position = DisplayServer.mouse_get_position()
	_menu.reset_size()
	_menu.popup()

## The icon of a menu item, by the words in it; none where there is no editor (previews)
func _get_menu_icon(text: String) -> Texture2D:
	var lower: String = text.to_lower()
	for words: Array in MENU_ICONS:
		for word: String in words[0]: if lower.contains(word): return _get_editor_icon(words[1])
	return _get_editor_icon("Object")

## [param pick] gets the actions when [param node] is right-clicked
func _on_right_click(node: GraphElement, pick: Callable) -> void:
	node.gui_input.connect(func(input: InputEvent) -> void:
		var click: InputEventMouseButton = input as InputEventMouseButton
		if click != null and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
			_show_menu(pick.call())
			accept_event()
	)

## One change as one undo step
func _request(resource: Resource, property: StringName, value: Variant, action: String, file: Resource) -> void:
	var changes: Array[Array] = [[resource, property, value]]
	changes_requested.emit(changes, action, file)

## A toolbar button forgetting where this graph's nodes were moved, after asking
func _add_tidy_button() -> void:
	var ask: ConfirmationDialog = ConfirmationDialog.new()
	ask.dialog_text = "Put every node here back in its default place?"
	ask.confirmed.connect(_tidy)
	add_child(ask, false, Node.INTERNAL_MODE_FRONT)
	var button: Button = Button.new()
	button.flat = true
	button.icon = _get_editor_icon("Reload")
	if button.icon == null: button.text = "Tidy"
	button.tooltip_text = "Tidy: put every node back in its default place"
	button.pressed.connect(ask.popup_centered)
	get_menu_hbox().add_child(button)

## Placed special nodes keep their positions: those are all they are
func _tidy() -> void:
	if layout == null: return
	for key: String in _nodes: if not AdventureLayout.is_placed_special(key): layout.positions.erase(key)
	layout_changed.emit()
	tidied.emit()

func _on_delete_nodes(names: Array[StringName]) -> void:
	for node_name: StringName in names: _on_delete_key(get_node(NodePath(node_name)) as GraphElement)

## The Delete key on a selected node: what it shows is deleted, if it can be
func _on_delete_key(element: GraphElement) -> void:
	var resource: Resource = _resources.get(element)
	if resource is AdventureArea or resource is AdventurePage and not AdventureEventEditing.is_inside_file(resource as AdventurePage): deletion_requested.emit(resource)

## Paths dragged from the FileSystem panel
static func _get_dropped_files(data: Variant) -> PackedStringArray:
	if not data is Dictionary or (data as Dictionary).get("type") != "files": return PackedStringArray()
	return (data as Dictionary)["files"]

static func _is_image(path: String) -> bool: return IMAGE_EXTENSIONS.has(path.get_extension().to_lower())

## The node at [param point] on the graph, if any
func _get_node_at(point: Vector2) -> GraphNode:
	for element: GraphElement in _resources:
		if element is GraphNode and Rect2(element.position_offset, element.size).has_point(point): return element as GraphNode
	return null

## The page whose node is at [param point] on the graph
func _get_page_at(point: Vector2) -> AdventurePage:
	var node: GraphNode = _get_node_at(point)
	return _resources[node] as AdventurePage if node != null else null

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
	_mark_problems(node, resource)
	return node

## A warning icon in the title bar, a reddish node and the problems as its tooltip
func _mark_problems(node: GraphNode, resource: Resource) -> void:
	var texts: Array[String] = [ ]
	for problem: AdventureProblems.Problem in problems: if problem.page == resource and not texts.has(problem.text): texts.append(problem.text)
	if texts.is_empty(): return
	node.self_modulate = PROBLEM_COLOR
	node.tooltip_text = "\n".join(texts)
	var icon: TextureRect = _make_texture_rect(_get_editor_icon("StatusWarning"))
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
	node.get_titlebar_hbox().add_child(icon)
	node.get_titlebar_hbox().move_child(icon, 0)

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

func _add_dashed(from: Control, to: Control, color: Color = DASHED_COLOR) -> void: _add_line(from, to, color, true, 0)

## Between two nodes: straight from edge to edge, toward each other's center; otherwise from the sides facing each other
func _add_line(from: Control, to: Control, color: Color, dashed: bool, arrows: int) -> void:
	_dashed.append([from, to, color, dashed, arrows])
	# Ends inside a node move when the node lays itself out
	for end: Control in [from, to]: if not end is GraphNode: end.item_rect_changed.connect(_dashed_layer.queue_redraw)
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
	card.gui_input.connect(func(input: InputEvent) -> void:
		var click: InputEventMouseButton = input as InputEventMouseButton
		if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_RIGHT: return
		var actions: Dictionary[String, Callable] = _get_event_card_actions(event, page)
		if actions.is_empty(): return
		_show_menu(actions)
		card.accept_event()
	)
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

func _make_icon(texture: Texture2D, color: Color) -> TextureRect:
	var icon: TextureRect = _make_texture_rect(texture)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.custom_minimum_size = Vector2.ONE * ICON_SIZE
	icon.modulate = color
	return icon

## An editor icon, or [param fallback] text where there is no editor (previews)
func _make_tool_button(icon_name: String, fallback: String, tooltip: String, on_pressed: Callable) -> Button:
	var button: Button = Button.new()
	button.flat = true
	button.icon = _get_editor_icon(icon_name)
	if button.icon == null: button.text = fallback
	button.tooltip_text = tooltip
	button.pressed.connect(on_pressed)
	return button

static func _get_editor_icon(icon_name: String) -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon(icon_name, &"EditorIcons") if Engine.is_editor_hint() else null

func _on_node_selected(element: Node) -> void:
	var resource: Resource = _resources.get(element as GraphElement)
	if resource != null: EditorInterface.edit_resource(resource)

func _on_end_node_move() -> void:
	if layout == null: return
	for key: String in _nodes: layout.positions[key] = _nodes[key].position_offset
	layout_changed.emit()

## Dashed links: GraphEdit's connections can't be dashed; drawn above frames and nodes, which would hide them
func _add_dashed_layer() -> void:
	_dashed_layer = Control.new()
	_dashed_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dashed_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dashed_layer.draw.connect(_draw_dashed)
	# Above the nodes too: GraphEdit draws its elements after its internal children
	_dashed_layer.z_index = 1
	add_child(_dashed_layer, false, Node.INTERNAL_MODE_FRONT)

func _draw_dashed() -> void:
	var to_local: Transform2D = _dashed_layer.get_global_transform().affine_inverse()
	for line: Array in _dashed:
		if not is_instance_valid(line[0]) or not is_instance_valid(line[1]): continue
		var from: Rect2 = (line[0] as Control).get_global_rect()
		var to: Rect2 = (line[1] as Control).get_global_rect()
		var start: Vector2
		var end: Vector2
		if line[0] is GraphNode and line[1] is GraphNode:
			start = _get_edge_point(from, to.get_center())
			end = _get_edge_point(to, from.get_center())
		else:
			var forward: bool = to.get_center().x >= from.get_center().x
			start = Vector2(from.end.x if forward else from.position.x, from.get_center().y)
			end = Vector2(to.position.x if forward else to.end.x, to.get_center().y)
		start = to_local * start
		end = to_local * end
		if line[3]: _dashed_layer.draw_dashed_line(start, end, line[2], 2.0 * zoom, 10.0 * zoom)
		else: _dashed_layer.draw_line(start, end, line[2], 2.0 * zoom, true)
		if line[4] & ARROW_END: _draw_arrow(start, end, line[2])
		if line[4] & ARROW_START: _draw_arrow(end, start, line[2])

## Where the line from [param rect]'s center toward [param toward] leaves it
static func _get_edge_point(rect: Rect2, toward: Vector2) -> Vector2:
	var center: Vector2 = rect.get_center()
	var direction: Vector2 = toward - center
	if direction.is_zero_approx(): return center
	var half: Vector2 = rect.size / 2
	var factor: float = minf(half.x / absf(direction.x) if direction.x != 0 else INF, half.y / absf(direction.y) if direction.y != 0 else INF)
	return center + direction * factor

func _draw_arrow(from: Vector2, tip: Vector2, color: Color) -> void:
	var back: Vector2 = (from - tip).normalized() * ARROW_SIZE * zoom
	_dashed_layer.draw_colored_polygon(PackedVector2Array([tip, tip + back.rotated(0.45), tip + back.rotated(-0.45)]), color)
