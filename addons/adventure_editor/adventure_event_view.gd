@tool
class_name AdventureEventView
extends AdventureCardView

## One event at a glance ([AdventureEventOverview]): a frame per event (a scenario: per option) and per sub-event, each with the pages behind it,
## special nodes ("Host", "Previous location": one host per frame always, more dragged in from the sidebar) and the locations it leads to; sub-events hang dashed from the page listing them.
## Page cards and their decision cards and tags: [AdventureCardView].
## Edits are only requested here; [AdventureEditor] makes them (undo, saving). [param file]: the file the change is stored in

## An exit or the picked host was double-clicked
signal exit_opened(location: AdventurePage)
## A new event as an option of [param scenario]
signal option_requested(scenario: AdventureEventScenario)
## An event already made, to show around [param event]'s locations
signal nearby_event_requested(event: AdventurePage)

enum Target { PAGE, HOST, PREVIOUS }

const PREVIOUS_COLOR: Color = Color(0.7, 0.55, 0.95)
const PREVIOUS_ICON: Texture2D = preload("uid://dmkjss474288g")  # exit-door.svg
## Special nodes by kind: [name in layout keys and drag data, title, hint, color, icon]
const SPECIALS: Dictionary[Target, Array] = {
	Target.HOST: ["host", "Host", "Back to the page the event is on", HOST_COLOR, HOST_ICON],
	Target.PREVIOUS: ["previous", "Previous location", "Back to where the player was before the host", PREVIOUS_COLOR, PREVIOUS_ICON],
}
## Where a default "Previous location" sits below the host
const SPECIAL_SPACING: float = 140.0
const NODE_GAP: float = 40.0

var _overview: AdventureEventOverview
## The host picked to see the event at; none: any host
var _host: AdventurePage
## By node name: the entry, the page whose decisions it shows, what its output ports lead to, and what a link onto it leads to ([Target, page])
var _node_entries: Dictionary[StringName, AdventureEventOverview.Entry] = {}
var _node_pages: Dictionary[StringName, AdventurePage] = {}
var _node_ports: Dictionary[StringName, Array] = {}
var _node_targets: Dictionary[StringName, Array] = {}
var _frame_entries: Dictionary[GraphFrame, AdventureEventOverview.Entry] = {}
## [nodes, top] per column placed by default, stacked once laid out; showing again drops them with the nodes
var _unstacked: Array[Array] = [ ]

func setup() -> void:
	super()
	right_disconnects = true
	connection_request.connect(_on_connection_request)
	disconnection_request.connect(func(from: StringName, port: int, _to: StringName, _to_port: int) -> void: _request_reference(from, port, null))
	connection_to_empty.connect(_on_connection_to_empty)

func get_event() -> AdventurePage: return _overview.root if _overview != null else null

func get_host() -> AdventurePage: return _host

## No event: empty
func show_event(event: AdventurePage, host: AdventurePage = null) -> void:
	_clear()
	_host = host
	for nodes: Dictionary in [_node_entries, _node_pages, _node_ports, _node_targets, _card_styles, _frame_entries, _tags, _tag_owners, _fight_cards, _fight_pages]: nodes.clear()
	_unstacked.clear()
	_overview = AdventureEventOverview.new(event) if event != null else null
	if _overview == null: return
	# Fights first: conditions can offer their monsters
	for entry: AdventureEventOverview.Entry in _overview.entries:
		for page: AdventurePage in entry.graph.pages:
			for decision: AdventureDecision in page.decisions: if decision is AdventureFightDecision: _fight_pages[decision] = page
	var origin: Vector2 = Vector2.ZERO
	for entry: AdventureEventOverview.Entry in _overview.entries:
		# A scenario's switch (and the scenarios around it) before its first option
		var chain: Array[AdventureEventOverview.Switch] = [ ]
		var switch: AdventureEventOverview.Switch = entry.switch
		while switch != null:
			chain.push_front(switch)
			switch = switch.outer
		for outer: AdventureEventOverview.Switch in chain:
			if _nodes.has(_switch_key(outer.scenario)): continue
			_add_switch(outer, origin)
			origin.x += NODE_SPACING.x * 1.25
		var frame: GraphFrame = _add_frame(entry.label, entry.event, null)
		_frame_entries[frame] = entry
		origin.x += (_add_entry(entry, frame, origin) + 1) * NODE_SPACING.x
	for switch: AdventureEventOverview.Switch in _overview.switches: _connect_switch(switch)
	for entry: AdventureEventOverview.Entry in _overview.entries:
		if entry.parent != null and entry.switch == null: _add_dashed(_nodes[_key(entry.parent, entry.parent_page)], _nodes[_key(entry, entry.event)])
	for switch: AdventureEventOverview.Switch in _overview.switches:
		if switch.parent != null and switch.outer == null: _add_dashed(_nodes[_key(switch.parent, switch.parent_page)], _nodes[_switch_key(switch.scenario)])
	_add_condition_lines()

## Adds the entry's nodes to [param frame] from [param origin] on; returns how many columns they take
func _add_entry(entry: AdventureEventOverview.Entry, frame: GraphFrame, origin: Vector2) -> int:
	var graph: AdventureEventGraph = entry.graph
	# Default places: a column per step from the event, stacked by height once the nodes are laid out
	var columns: Dictionary[int, Array] = {}
	for page: AdventurePage in graph.pages + graph.exits:
		var depth: int = graph.depths[page]
		var at: Vector2 = origin + Vector2(depth * NODE_SPACING.x, 0)
		var placed: bool = layout != null and layout.positions.has(_key(entry, page))
		var node: GraphNode = _add_exit(entry, page, at) if graph.exits.has(page) else _add_page(entry, page, at)
		if not placed: columns.get_or_add(depth, [ ]).append(node)
		attach_graph_element_to_frame(node.name, frame.name)
	for column: Array in columns.values(): _unstacked.append([column, origin.y])
	if not get_tree().process_frame.is_connected(_stack): get_tree().process_frame.connect(_stack, CONNECT_ONE_SHOT)
	# Always there, so anything can be linked back to the host
	var column_count: int = graph.depths.values().max() + 1
	_add_specials(entry, frame, origin + Vector2(column_count * NODE_SPACING.x, 0))
	for page: AdventurePage in graph.pages:
		var ports: Array[AdventureEventGraph.Outlet] = AdventureEventGraph.get_ports(page)
		for port: int in ports.size():
			var target_key: String = ""
			if ports[port].to_host: target_key = _get_special_target(entry, ports[port], Target.HOST)
			elif ports[port].to_previous: target_key = _get_special_target(entry, ports[port], Target.PREVIOUS)
			elif ports[port].target != null: target_key = _key(entry, ports[port].target)
			if not target_key.is_empty(): connect_node(_nodes[_key(entry, page)].name, port, _nodes[target_key].name, 0)
	return column_count + 1

## Stacks each column of default-placed nodes below each other, once they are laid out
func _stack() -> void:
	for pending: Array in _unstacked:
		var y: float = pending[1]
		for node: GraphNode in pending[0]:
			node.position_offset.y = y
			y += node.size.y + NODE_GAP
	_unstacked.clear()

## The page with its whole text and its decisions as cards; the event's node also says when it shows, what it hides and whose its monsters are
func _add_page(entry: AdventureEventOverview.Entry, page: AdventurePage, at: Vector2) -> GraphNode:
	var content: VBoxContainer = _make_page_content(page)
	if not page.description.is_empty(): content.add_child(_make_text(page.description))
	if page == entry.event:
		content.add_child(_make_info("When:"))
		content.add_child(_make_condition_tags(page, _file_for(null, page, entry)))
		for text: String in [AdventureEventOverview.get_hiding_text(entry, _host), AdventureEventOverview.get_monster_text(entry)]:
			if not text.is_empty(): content.add_child(_make_info(text))
	var node: GraphNode = _add_node(_key(entry, page), page, AdventureGraph.get_title(page), content, at)
	# An option's event is linked from its scenario's switch
	node.set_slot(0, page != entry.event or entry.switch != null, 0, Color.WHITE, false, 0, Color.WHITE)
	var outlets: Array[AdventureEventGraph.Outlet] = AdventureEventGraph.get_outlets(page)
	for index: int in outlets.size(): _add_decision_cards(node, entry, page, index, outlets[index])
	# What the game offers on a page without decisions
	var ports: Array[AdventureEventGraph.Outlet] = AdventureEventGraph.get_ports(page)
	# What the game offers on a page without decisions; linking it makes it a real choice
	if outlets.is_empty():
		var automatic: AdventureEventGraph.Outlet = AdventureEventGraph.Outlet.new()
		automatic.label = "Turn back."
		ports.append(automatic)
		# Back one page after an event is nearly always the host, so it looks like one
		var turn_back: HBoxContainer = HBoxContainer.new()
		turn_back.tooltip_text = "The game's automatic \"Turn back.\" (back 1); link it to continue elsewhere"
		turn_back.add_child(_make_icon(HOST_ICON, HOST_COLOR))
		var label: Label = Label.new()
		label.text = "Turn back (automatic)"
		label.modulate = HOST_COLOR
		turn_back.add_child(label)
		node.add_child(turn_back)
		node.set_slot(node.get_child_count() - 1, false, 0, Color.WHITE, true, 0, HOST_COLOR)
	node.add_child(_make_add_bar(entry, page))
	_remember(node, entry, page, ports, [Target.PAGE, page])
	_on_right_click(node, func() -> Dictionary[String, Callable]: return _get_page_actions(entry, page))
	return node

## Adding decisions, and deleting pages stored inside the file (nothing else deletes them, so links can't lose them by accident)
func _get_page_actions(entry: AdventureEventOverview.Entry, page: AdventurePage) -> Dictionary[String, Callable]:
	var actions: Dictionary[String, Callable] = _get_add_actions(entry, page)
	if page != entry.event and AdventureEventEditing.is_inside_file(page): actions["Delete page"] = _delete_page.bind(entry, page)
	if page == entry.event: actions["Add nearby event…"] = nearby_event_requested.emit.bind(page)
	if page == entry.event and not AdventureEventEditing.is_inside_file(page): actions["Delete event…"] = deletion_requested.emit.bind(page)
	actions["Play from here"] = play_requested.emit.bind(page, entry.event)
	if page == entry.event and entry.is_nearby:
		var source: AdventurePage = entry.parent_page
		var without: Array[AdventurePage] = source.nearby_events.duplicate()
		without.erase(page)
		actions["Not nearby %s any more" % AdventureGraph.get_title(source)] = _request.bind(source, &"nearby_events", without, "Not nearby any more", load(AdventureEventEditing.get_file_path(source)))
	return actions

## Everything in the file pointing at the page goes back instead
func _delete_page(entry: AdventureEventOverview.Entry, page: AdventurePage) -> void:
	var file: Resource = _file_for(null, page, entry)
	if not file is AdventurePage: return
	var changes: Array[Array] = [ ]
	for reference: Array in AdventureEventEditing.find_references_to(file as AdventurePage, page): changes.append([reference[0], reference[1], null])
	changes_requested.emit(changes, "Delete %s" % AdventureGraph.get_title(page), file)

func _add_exit(entry: AdventureEventOverview.Entry, location: AdventurePage, at: Vector2) -> GraphNode:
	var node: GraphNode = _add_node(_key(entry, location), location, AdventureGraph.get_title(location), _make_label("Location (double-click: map)"), at)
	node.modulate = FADED
	node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
	_open_on_double_click(node, location)
	_remember(node, entry, null, [ ], [Target.PAGE, location])
	return node

## The frame's own host (always), the special nodes placed from the sidebar, and a "Previous location" if something leads there but none is placed
func _add_specials(entry: AdventureEventOverview.Entry, frame: GraphFrame, at: Vector2) -> void:
	var nodes: Array[GraphNode] = [_add_special(entry, Target.HOST, _special_key(entry, Target.HOST), at, false)]
	if layout != null:
		for key: String in layout.positions:
			if not key.begins_with(_placed_prefix(entry)): continue
			var kind_name: String = key.trim_prefix(_placed_prefix(entry)).get_slice("/", 0)
			for kind: Target in SPECIALS: if SPECIALS[kind][0] == kind_name: nodes.append(_add_special(entry, kind, key, at, true))
	var needs_previous: bool = false
	for page: AdventurePage in entry.graph.pages:
		for port: AdventureEventGraph.Outlet in AdventureEventGraph.get_ports(page):
			if port.to_previous and _get_placed_target(entry, port, Target.PREVIOUS).is_empty(): needs_previous = true
	if needs_previous: nodes.append(_add_special(entry, Target.PREVIOUS, _special_key(entry, Target.PREVIOUS), at + Vector2(0, SPECIAL_SPACING), false))
	for node: GraphNode in nodes: attach_graph_element_to_frame(node.name, frame.name)

## [param removable]: placed from the sidebar
func _add_special(entry: AdventureEventOverview.Entry, kind: Target, key: String, at: Vector2, removable: bool) -> GraphNode:
	var special: Array = SPECIALS[kind]
	var title: String = AdventureGraph.get_title(_host) if kind == Target.HOST and _host != null else special[1]
	var hint: String = special[2] + (" (double-click: map)" if kind == Target.HOST and _host != null else "")
	var node: GraphNode = _add_node(key, _host if kind == Target.HOST and _host != null else entry.event, title, _make_label(hint), at)
	node.self_modulate = special[3]
	node.get_titlebar_hbox().add_child(_make_icon(special[4], Color.WHITE))
	node.get_titlebar_hbox().move_child(node.get_titlebar_hbox().get_child(-1), 0)
	node.set_slot(0, true, 0, special[3], false, 0, Color.WHITE)
	if kind == Target.HOST: _open_on_double_click(node, _host)
	if removable: _on_right_click(node, func() -> Dictionary[String, Callable]: return {"Remove": _remove_special.bind(key)})
	_remember(node, entry, null, [ ], [kind, null])
	return node

## Its links go to the frame's own special node again
func _remove_special(key: String) -> void:
	layout.positions.erase(key)
	for link: String in layout.special_links.keys(): if layout.special_links[link] == key: layout.special_links.erase(link)
	layout_changed.emit()
	show_event(get_event(), _host)

## The special node a host / previous location link is drawn to: the placed one it was linked to, else the frame's own
func _get_special_target(entry: AdventureEventOverview.Entry, outlet: AdventureEventGraph.Outlet, kind: Target) -> String:
	var placed: String = _get_placed_target(entry, outlet, kind)
	return placed if not placed.is_empty() else _special_key(entry, kind)

func _get_placed_target(entry: AdventureEventOverview.Entry, outlet: AdventureEventGraph.Outlet, kind: Target) -> String:
	var reference: Resource = outlet.decision.get(outlet.property) as Resource
	var key: String = layout.special_links.get(_key(entry, reference), "") if layout != null and reference != null else ""
	return key if _nodes.has(key) and (_node_targets.get(_nodes[key].name, [ ]) as Array).size() > 0 and _node_targets[_nodes[key].name][0] == kind else ""

## Special nodes dragged in from the sidebar ([AdventureSpecialButton]) land in the frame under the mouse
## Images from the FileSystem panel onto a page become its background
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if data is Dictionary and (data as Dictionary).has("adventure_special"): return true
	var files: PackedStringArray = _get_dropped_files(data)
	return not files.is_empty() and _is_image(files[0]) and _get_page_at(_to_graph(at_position)) != null

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var at: Vector2 = _to_graph(at_position)
	var files: PackedStringArray = _get_dropped_files(data)
	if not files.is_empty():
		var node: GraphNode = _get_node_at(at)
		var page: AdventurePage = _resources[node] as AdventurePage
		var texture: Texture2D = load(files[0]) as Texture2D
		if texture != null and _node_entries.has(node.name): _request(page, &"background", texture, "Set background", _file_for(null, page, _node_entries[node.name]))
		return
	for frame: GraphFrame in _frame_entries:
		if not Rect2(frame.position_offset, frame.size).has_point(at): continue
		var prefix: String = "%s%s/" % [_placed_prefix(_frame_entries[frame]), (data as Dictionary)["adventure_special"]]
		var index: int = 0
		while layout.positions.has(prefix + str(index)): index += 1
		layout.positions[prefix + str(index)] = at
		layout_changed.emit()
		show_event(get_event(), _host)
		return
	push_warning("Drop special nodes into an event's frame")

func _open_on_double_click(node: GraphNode, location: AdventurePage) -> void:
	if location == null: return
	node.gui_input.connect(func(input: InputEvent) -> void:
		var click: InputEventMouseButton = input as InputEventMouseButton
		if click != null and click.double_click: exit_opened.emit(location)
	)

func _remember(node: GraphNode, entry: AdventureEventOverview.Entry, page: AdventurePage, ports: Array[AdventureEventGraph.Outlet], target: Array) -> void:
	_node_entries[node.name] = entry
	_node_pages[node.name] = page
	_node_ports[node.name] = ports
	_node_targets[node.name] = target

func _on_connection_request(from: StringName, port: int, to: StringName, _to_port: int) -> void:
	var target: Array = _node_targets.get(to, [ ])
	var outlet: AdventureEventGraph.Outlet = _get_port(from, port)
	if target.is_empty() or outlet == null: return
	if target[0] != Target.PAGE:
		var reference: AdventurePageReference = AdventureEventEditing.make_special_reference(target[0] == Target.PREVIOUS)
		# Before the request: applying it redraws the graph, which then draws the link to this node
		layout.special_links[_key(_node_entries[from], reference)] = _key_of_node(to)
		_request_reference(from, port, reference)
		layout_changed.emit()
		return
	var page: AdventurePage = target[1]
	if AdventureEventEditing.would_loop(_node_pages[from], page):
		push_warning("%s already leads back to here, and one file can't store a loop; use \"(back)\", the host or a page in its own file" % AdventureGraph.get_title(page))
		return
	_request_reference(from, port, AdventureEventEditing.make_reference(page, AdventureEventEditing.get_file_path(_file_for(outlet.decision, _node_pages[from], _node_entries[from]))))

## A new page inside the file, where the link was let go
func _on_connection_to_empty(from: StringName, port: int, release_position: Vector2) -> void:
	if _get_port(from, port) == null: return
	var page: AdventurePage = AdventureEventEditing.make_page()
	layout.positions[_key(_node_entries[from], page)] = _to_graph(release_position)
	_request_reference(from, port, page)

## None: unlinks. Refused if the page it pointed at is stored inside the file and nothing else points at it
func _request_reference(from: StringName, port: int, reference: AdventurePageReference) -> void:
	var outlet: AdventureEventGraph.Outlet = _get_port(from, port)
	if outlet == null: return
	var page: AdventurePage = _node_pages[from]
	var file: Resource = _file_for(outlet.decision, page, _node_entries[from])
	# The automatic "Turn back.": a choice leading there takes its place
	if outlet.decision == null:
		if reference == null: return
		var choice: AdventureDecision = AdventureEventEditing.make_choice()
		choice.description = "Continue."
		choice.transition = reference
		var decisions: Array[AdventureDecision] = [choice]
		_request(page, &"decisions", decisions, "Continue", file)
		return
	var old: AdventurePageReference = outlet.decision.get(outlet.property) as AdventurePageReference
	if old != null and old != reference and file is AdventurePage and AdventureEventEditing.would_lose_page(file as AdventurePage, [old]):
		push_warning("Only \"%s\" leads to %s, which is stored in this file; delete that page instead (right-click it)" % [outlet.label, AdventureGraph.get_title(old as AdventurePage)])
		return
	_request(outlet.decision, outlet.property, reference, "Unlink" if reference == null else "Link", file)

func _get_port(node_name: StringName, port: int) -> AdventureEventGraph.Outlet:
	var ports: Array = _node_ports.get(node_name, [ ])
	return ports[port] if port < ports.size() else null

## Pages stored inside a file are deleted as by their menu; events in files of their own are asked about; placed special nodes are removed
func _on_delete_key(element: GraphElement) -> void:
	var entry: AdventureEventOverview.Entry = _node_entries.get(element.name)
	var page: AdventurePage = _resources.get(element) as AdventurePage
	if entry != null and page != null and page != entry.event and AdventureEventEditing.is_inside_file(page): _delete_page(entry, page)
	elif AdventureLayout.is_placed_special(_key_of_node(element.name)): _remove_special(_key_of_node(element.name))
	else: super(element)

## A sub-event's card shows its frame (a scenario: its switch); others open the event
func _on_event_card_pressed(event: AdventurePage, _page: AdventurePage) -> void:
	if _nodes.has(_switch_key(event)):
		focus_node(_nodes[_switch_key(event)])
		return
	var entry: AdventureEventOverview.Entry = _overview.get_listed_entry(event)
	if entry != null: focus_node(_nodes[_key(entry, entry.event)])
	else: event_opened.emit(event, null)

## A scenario picking the first of its options that fits: a row per option in priority order (▲ ▼ ✕), linked to the option, and "+ option"
func _add_switch(switch: AdventureEventOverview.Switch, at: Vector2) -> void:
	var scenario: AdventureEventScenario = switch.scenario
	var file: Resource = load(AdventureEventEditing.get_file_path(scenario))
	var content: VBoxContainer = VBoxContainer.new()
	content.custom_minimum_size.x = THUMBNAIL_SIZE.x
	content.add_child(_make_info("Shows the first option that fits. When:"))
	content.add_child(_make_condition_tags(scenario, file))
	var node: GraphNode = _add_node(_switch_key(scenario), scenario, "%s (scenario)" % AdventureGraph.get_title(scenario), content, at)
	node.set_slot(0, switch.outer != null, 0, Color.WHITE, false, 0, Color.WHITE)
	var options: Array[AdventurePage] = scenario.events
	for index: int in options.size():
		var row: HBoxContainer = HBoxContainer.new()
		var conditions: String = AdventureEventOverview.get_condition_text(options[index].conditions)
		var label: Label = _make_label("%d · %s%s" % [index + 1, AdventureGraph.get_title(options[index]), "\nwhen %s" % conditions if not conditions.is_empty() else ""])
		label.custom_minimum_size.x = THUMBNAIL_SIZE.x - 3 * ICON_SIZE - 24
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)
		if index > 0: row.add_child(_make_tool_button("MoveUp", "▲", "Earlier: checked first", _move_option.bind(scenario, file, index, -1)))
		if index < options.size() - 1: row.add_child(_make_tool_button("MoveDown", "▼", "Later", _move_option.bind(scenario, file, index, 1)))
		row.add_child(_make_tool_button("Remove", "✕", "Not an option any more (its file stays)", _remove_option.bind(scenario, file, index)))
		node.add_child(row)
		node.set_slot(node.get_child_count() - 1, false, 0, Color.WHITE, true, 0, Color.WHITE)
	node.add_child(_make_info("Otherwise: nothing"))
	var add: Button = _make_tool_button("Add", "+", "A new event as the last option", option_requested.emit.bind(scenario))
	add.text = "option"
	node.add_child(add)

## Each option's row to its event (a scenario option: to its switch)
func _connect_switch(switch: AdventureEventOverview.Switch) -> void:
	var options: Array[AdventurePage] = switch.scenario.events
	for index: int in options.size():
		var target: String = _switch_key(options[index]) if options[index] is AdventureEventScenario else ""
		var entry: AdventureEventOverview.Entry = _overview.get_entry(options[index])
		if target.is_empty() and entry != null: target = _key(entry, entry.event)
		if _nodes.has(target): connect_node(_nodes[_switch_key(switch.scenario)].name, index, _nodes[target].name, 0)

func _move_option(scenario: AdventureEventScenario, file: Resource, index: int, step: int) -> void:
	var options: Array[AdventurePage] = scenario.events.duplicate()
	var option: AdventurePage = options.pop_at(index)
	options.insert(index + step, option)
	_request(scenario, &"events", options, "Move %s" % AdventureGraph.get_title(option), file)

func _remove_option(scenario: AdventureEventScenario, file: Resource, index: int) -> void:
	var options: Array[AdventurePage] = scenario.events.duplicate()
	var option: AdventurePage = options.pop_at(index)
	if AdventureEventEditing.is_inside_file(option):
		push_warning("%s is stored inside the scenario's file and would be lost" % AdventureGraph.get_title(option))
		return
	_request(scenario, &"events", options, "Remove %s" % AdventureGraph.get_title(option), file)

func _switch_key(scenario: AdventurePage) -> String:
	return AdventureLayout.get_switch_key(_overview.root, scenario)

func _key(entry: AdventureEventOverview.Entry, resource: Resource) -> String:
	return AdventureLayout.get_event_key(_overview.root, entry.event, AdventureLayout.get_key(resource))

## The frame's own special node of [param kind]
func _special_key(entry: AdventureEventOverview.Entry, kind: Target) -> String:
	return AdventureLayout.get_event_key(_overview.root, entry.event, SPECIALS[kind][0])

## Keys of special nodes placed from the sidebar start with this, then "<kind>/<number>"
func _placed_prefix(entry: AdventureEventOverview.Entry) -> String:
	return AdventureLayout.get_placed_special_prefix(_overview.root, entry.event)

func _key_of_node(node_name: StringName) -> String:
	for key: String in _nodes: if _nodes[key].name == node_name: return key
	return ""
