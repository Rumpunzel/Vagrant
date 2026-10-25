@tool
class_name AdventureEventView
extends AdventureGraphView

## One event at a glance ([AdventureEventOverview]): a frame per event (a scenario: per option) and per sub-event, each with the pages behind it,
## a port per decision outcome, "↺ Host" and the locations it leads to; sub-events hang dashed from the page listing them

## An exit or the picked host was double-clicked
signal exit_opened(location: AdventurePage)

var _overview: AdventureEventOverview
## The host picked to see the event at; none: any host
var _host: AdventurePage

func get_event() -> AdventurePage: return _overview.root if _overview != null else null
func get_host() -> AdventurePage: return _host

## No event: empty
func show_event(event: AdventurePage, host: AdventurePage = null) -> void:
	_clear()
	_host = host
	_overview = AdventureEventOverview.new(event) if event != null else null
	if _overview == null: return
	var origin: Vector2 = Vector2.ZERO
	for entry: AdventureEventOverview.Entry in _overview.entries:
		var frame: GraphFrame = _add_frame(entry.label, entry.event, null)
		origin.x += (_add_entry(entry, frame, origin) + 1) * NODE_SPACING.x
	for entry: AdventureEventOverview.Entry in _overview.entries:
		if entry.parent != null: _add_dashed(_nodes[_key(entry.parent, entry.parent_page)], _nodes[_key(entry, entry.event)])

## Adds the entry's nodes to [param frame] from [param origin] on; returns how many columns they take
func _add_entry(entry: AdventureEventOverview.Entry, frame: GraphFrame, origin: Vector2) -> int:
	var graph: AdventureEventGraph = entry.graph
	var column_sizes: Dictionary[int, int] = {}
	var columns: int = 0
	for page: AdventurePage in graph.pages + graph.exits:
		var depth: int = graph.depths[page]
		var row: int = column_sizes.get(depth, 0)
		column_sizes[depth] = row + 1
		columns = maxi(columns, depth + 1)
		var at: Vector2 = origin + Vector2(depth, row) * NODE_SPACING
		var node: GraphNode = _add_exit(entry, page, at) if graph.exits.has(page) else _add_page(entry, page, at)
		attach_graph_element_to_frame(node.name, frame.name)
	if graph.leads_to_host:
		attach_graph_element_to_frame(_add_host(entry, origin + Vector2(columns, 0) * NODE_SPACING).name, frame.name)
		columns += 1
	for page: AdventurePage in graph.pages:
		var outlets: Array[AdventureEventGraph.Outlet] = AdventureEventGraph.get_outlets(page)
		for port: int in outlets.size():
			var target_key: String = ""
			if outlets[port].to_host: target_key = _host_key(entry)
			elif outlets[port].target != null: target_key = _key(entry, outlets[port].target)
			if not target_key.is_empty(): connect_node(_nodes[_key(entry, page)].name, port, _nodes[target_key].name, 0)
	return columns

func _add_page(entry: AdventureEventOverview.Entry, page: AdventurePage, at: Vector2) -> GraphNode:
	var content: VBoxContainer = _make_page_content(page)
	if page == entry.event:
		var when: String = AdventureEventOverview.get_condition_text(entry)
		if not when.is_empty(): content.add_child(_make_label("When: %s" % when))
		for text: String in [AdventureEventOverview.get_hiding_text(entry, _host), AdventureEventOverview.get_monster_text(entry)]:
			if not text.is_empty(): content.add_child(_make_label(text))
	var node: GraphNode = _add_node(_key(entry, page), page, AdventureGraph.get_title(page), content, at)
	node.set_slot(0, page != entry.event, 0, Color.WHITE, false, 0, Color.WHITE)
	for outlet: AdventureEventGraph.Outlet in AdventureEventGraph.get_outlets(page):
		var label: Label = Label.new()
		label.text = outlet.label
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if outlet.target == null and not outlet.to_host: label.modulate = FADED
		node.add_child(label)
		node.set_slot(node.get_child_count() - 1, false, 0, Color.WHITE, true, 0, Color.WHITE)
	return node

func _add_exit(entry: AdventureEventOverview.Entry, location: AdventurePage, at: Vector2) -> GraphNode:
	var node: GraphNode = _add_node(_key(entry, location), location, AdventureGraph.get_title(location), _make_label("Location (double-click: map)"), at)
	_fade_and_open_on_double_click(node, location)
	return node

func _add_host(entry: AdventureEventOverview.Entry, at: Vector2) -> GraphNode:
	var title: String = "↺ %s" % AdventureGraph.get_title(_host) if _host != null else "↺ Host"
	var hint: String = "The page the event is on (double-click: map)" if _host != null else "The page the event is on"
	var node: GraphNode = _add_node(_host_key(entry), _host if _host != null else entry.event, title, _make_label(hint), at)
	_fade_and_open_on_double_click(node, _host)
	return node

func _fade_and_open_on_double_click(node: GraphNode, location: AdventurePage) -> void:
	node.modulate = FADED
	node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
	if location == null: return
	node.gui_input.connect(func(input: InputEvent) -> void:
		var click: InputEventMouseButton = input as InputEventMouseButton
		if click != null and click.double_click: exit_opened.emit(location)
	)

## A sub-event's card shows its frame; others open the event
func _on_event_card_pressed(event: AdventurePage, _page: AdventurePage) -> void:
	var entry: AdventureEventOverview.Entry = _overview.get_listed_entry(event)
	if entry != null: focus_node(_nodes[_key(entry, entry.event)])
	else: event_opened.emit(event, null)

func _key(entry: AdventureEventOverview.Entry, page: AdventurePage) -> String:
	return "%s/%s/%s" % [AdventureLayout.get_key(_overview.root), AdventureLayout.get_key(entry.event), AdventureLayout.get_key(page)]

func _host_key(entry: AdventureEventOverview.Entry) -> String:
	return "%s/%s/host" % [AdventureLayout.get_key(_overview.root), AdventureLayout.get_key(entry.event)]
