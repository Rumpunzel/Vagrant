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
	var placed: Array[Resource] = [ ]
	placed.append_array(graph.pages)
	placed.append_array(graph.checks)
	placed.append_array(graph.exits)
	for resource: Resource in placed:
		var depth: int = graph.depths[resource]
		var row: int = column_sizes.get(depth, 0)
		column_sizes[depth] = row + 1
		columns = maxi(columns, depth + 1)
		var at: Vector2 = origin + Vector2(depth, row) * NODE_SPACING
		var node: GraphNode
		if resource is AdventureDecision: node = _add_check(entry, resource as AdventureDecision, at)
		elif graph.exits.has(resource): node = _add_exit(entry, resource as AdventurePage, at)
		else: node = _add_page(entry, resource as AdventurePage, at)
		attach_graph_element_to_frame(node.name, frame.name)
	if graph.leads_to_host:
		attach_graph_element_to_frame(_add_host(entry, origin + Vector2(columns, 0) * NODE_SPACING).name, frame.name)
		columns += 1
	for page: AdventurePage in graph.pages: _connect_outlets(entry, _key(entry, page), AdventureEventGraph.get_outlets(page))
	for check: AdventureDecision in graph.checks: _connect_outlets(entry, _key(entry, check), AdventureEventGraph.get_outcomes(check))
	return columns

func _connect_outlets(entry: AdventureEventOverview.Entry, from_key: String, outlets: Array[AdventureEventGraph.Outlet]) -> void:
	for port: int in outlets.size():
		var outlet: AdventureEventGraph.Outlet = outlets[port]
		var target_key: String = ""
		if outlet.to_check: target_key = _key(entry, outlet.decision)
		elif outlet.to_host: target_key = _host_key(entry)
		elif outlet.target != null: target_key = _key(entry, outlet.target)
		if not target_key.is_empty(): connect_node(_nodes[from_key].name, port, _nodes[target_key].name, 0)

## The page with its whole text; the event's node also says when it shows, what it hides and whose its monsters are
func _add_page(entry: AdventureEventOverview.Entry, page: AdventurePage, at: Vector2) -> GraphNode:
	var content: VBoxContainer = _make_page_content(page)
	if not page.description.is_empty(): content.add_child(_make_text(page.description))
	if page == entry.event:
		var when: String = AdventureEventOverview.get_condition_text(entry)
		if not when.is_empty(): content.add_child(_make_info("When: %s" % when))
		for text: String in [AdventureEventOverview.get_hiding_text(entry, _host), AdventureEventOverview.get_monster_text(entry)]:
			if not text.is_empty(): content.add_child(_make_info(text))
	var node: GraphNode = _add_node(_key(entry, page), page, AdventureGraph.get_title(page), content, at)
	node.set_slot(0, page != entry.event, 0, Color.WHITE, false, 0, Color.WHITE)
	_add_outlet_rows(node, AdventureEventGraph.get_outlets(page))
	return node

## A fight or save between its page and its outcomes
func _add_check(entry: AdventureEventOverview.Entry, check: AdventureDecision, at: Vector2) -> GraphNode:
	var node: GraphNode = _add_node(_key(entry, check), check, AdventureEventGraph.describe_check(check), _make_info(check.description), at)
	node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
	_add_outlet_rows(node, AdventureEventGraph.get_outcomes(check))
	return node

## A row with an output port per outlet; going back is faded, consequences follow the label
func _add_outlet_rows(node: GraphNode, outlets: Array[AdventureEventGraph.Outlet]) -> void:
	for outlet: AdventureEventGraph.Outlet in outlets:
		var label: Label = Label.new()
		var consequences: String = AdventureEventGraph.describe_consequences(outlet.consequences)
		label.text = outlet.label + (" (back)" if outlet.goes_back() else "") + (" · %s" % consequences if not consequences.is_empty() else "")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		if outlet.goes_back(): label.modulate = FADED
		node.add_child(label)
		node.set_slot(node.get_child_count() - 1, false, 0, Color.WHITE, true, 0, Color.WHITE)

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

func _key(entry: AdventureEventOverview.Entry, resource: Resource) -> String:
	return "%s/%s/%s" % [AdventureLayout.get_key(_overview.root), AdventureLayout.get_key(entry.event), AdventureLayout.get_key(resource)]

func _host_key(entry: AdventureEventOverview.Entry) -> String:
	return "%s/%s/host" % [AdventureLayout.get_key(_overview.root), AdventureLayout.get_key(entry.event)]
