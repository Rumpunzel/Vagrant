@tool
class_name AdventureEventView
extends AdventureCardView

## One plain event's pages ([AdventureEventOverview]): the event and the pages behind it, the special nodes ("Host", "Previous location": one host
## always, more dragged in from the sidebar) and the locations it leads to. Effects sit as chips where their outcome's line starts.
## Page cards and their decision cards and tags: [AdventureCardView].
## Edits are only requested here; [AdventureEditor] makes them (undo, saving). [param file]: the file the change is stored in

## An exit or the picked host was double-clicked
signal exit_opened(location: AdventurePage)

enum Target { PAGE, HOST, PREVIOUS }

## Effect chips of the stage picked on the encounter's screen
const PICKED_COLOR: Color = Color(0.6, 1.0, 0.6)
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

## The adventure's encounters, to find the one of the event shown
var encounters: Array[AdventureEncounter] = [ ]
## A stage picked on the encounter's screen ([track, stage]): the effects leading there are marked
var picked_stage: Array = [ ]
var _overview: AdventureEventOverview
## The host picked to see the event at; none: any host
var _host: AdventurePage
## By node name: the entry, the page whose decisions it shows, what its output ports lead to, and what a link onto it leads to ([Target, page])
var _node_entries: Dictionary[StringName, AdventureEventOverview.Entry] = {}
var _node_pages: Dictionary[StringName, AdventurePage] = {}
var _node_ports: Dictionary[StringName, Array] = {}
var _node_targets: Dictionary[StringName, Array] = {}
## [nodes, top] per column placed by default, stacked once laid out; showing again drops them with the nodes
var _unstacked: Array[Array] = [ ]

func setup() -> void:
	super()
	right_disconnects = true
	connection_request.connect(_on_connection_request)
	disconnection_request.connect(func(from: StringName, port: int, _to: StringName, _to_port: int) -> void: _request_reference(from, port, null))
	connection_to_empty.connect(_on_connection_to_empty)

func _get_encounter() -> AdventureEncounter:
	if _overview == null: return null
	for encounter: AdventureEncounter in encounters: if encounter.get_listed_events().has(_overview.root): return encounter
	return null

func get_event() -> AdventureEvent: return _overview.root if _overview != null else null

func get_host() -> AdventurePage: return _host

## No event: empty
func show_event(event: AdventureEvent, host: AdventurePage = null) -> void:
	_clear()
	_host = host
	_beaten_chips.clear()
	for nodes: Dictionary in [_node_entries, _node_pages, _node_ports, _node_targets, _card_styles, _tags, _tag_owners, _fight_cards, _fight_pages]: nodes.clear()
	_unstacked.clear()
	_overview = AdventureEventOverview.new(event) if event != null else null
	if _overview == null: return
	# Fights first: conditions can offer their monsters
	for entry: AdventureEventOverview.Entry in _overview.entries:
		for page: AdventurePage in entry.graph.pages:
			for decision: AdventureDecision in page.decisions: if decision is AdventureFightDecision: _fight_pages[decision] = page
	for entry: AdventureEventOverview.Entry in _overview.entries: _add_entry(entry, Vector2.ZERO)
	_highlight_picked()

## Adds the entry's nodes from [param origin] on; returns how many columns they take
func _add_entry(entry: AdventureEventOverview.Entry, origin: Vector2) -> int:
	var graph: AdventureEventGraph = entry.graph
	# Default places: a column per step from the event, stacked by height once the nodes are laid out
	var columns: Dictionary[int, Array] = {}
	for page: AdventurePage in graph.pages + graph.exits:
		var depth: int = graph.depths[page]
		var at: Vector2 = origin + Vector2(depth * NODE_SPACING.x, 0)
		var placed: bool = layout != null and layout.positions.has(_key(entry, page))
		var node: GraphNode = _add_exit(entry, page as AdventureLocation, at) if graph.exits.has(page) else _add_page(entry, page, at)
		if not placed: columns.get_or_add(depth, [ ]).append(node)
	for column: Array in columns.values(): _unstacked.append([column, origin.y])
	if not get_tree().process_frame.is_connected(_stack): get_tree().process_frame.connect(_stack, CONNECT_ONE_SHOT)
	# Always there, so anything can be linked back to the host
	var column_count: int = graph.depths.values().max() + 1
	_add_specials(entry, origin + Vector2(column_count * NODE_SPACING.x, 0))
	for page: AdventurePage in graph.pages:
		var ports: Array[AdventureEventGraph.Outlet] = AdventureEventGraph.get_ports(page)
		for port: int in ports.size():
			var target_key: String = ""
			if ports[port].to_host: target_key = _get_special_target(entry, ports[port], Target.HOST)
			elif ports[port].to_previous: target_key = _get_special_target(entry, ports[port], Target.PREVIOUS)
			elif ports[port].target != null: target_key = _key(entry, ports[port].target)
			if not target_key.is_empty(): connect_node(_nodes[_key(entry, page)].name, port, _nodes[target_key].name, 0)
	return column_count + 1

## The effect chips (and a won fight's "→ beaten") leading into the picked stage, marked
func _highlight_picked() -> void:
	if picked_stage.is_empty(): return
	var encounter: AdventureEncounter = _get_encounter()
	for item: Resource in _tags:
		var stage: AdventureStageConsequence = item as AdventureStageConsequence
		var kill: AdventureKillConsequence = item as AdventureKillConsequence
		var leads: bool = stage != null and _is_own(stage.subject, encounter) and picked_stage == [stage.track, stage.stage]
		leads = leads or kill != null and _is_own(kill.encounter, encounter) and picked_stage == [AdventureStoryline.BODY, AdventureStoryline.BODY_STATES[AdventureMonsterCondition.State.DEAD]]
		if leads: _tags[item].modulate = PICKED_COLOR
	if picked_stage == [AdventureStoryline.BODY, AdventureStoryline.BODY_STATES[AdventureMonsterCondition.State.BEATEN]]:
		for chip: Control in _beaten_chips: chip.modulate = PICKED_COLOR

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
		content.add_child(_make_condition_tags(entry.event, _file_for(null, page, entry)))
		for text: String in [AdventureEventOverview.get_hiding_text(entry, _host)]:
			if not text.is_empty(): content.add_child(_make_info(text))
	var node: GraphNode = _add_node(_key(entry, page), page, AdventureGraph.get_title(page), content, at)
	node.set_slot(0, page != entry.event, 0, Color.WHITE, false, 0, Color.WHITE)
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
	if page == entry.event and not AdventureEventEditing.is_inside_file(page): actions["Delete event…"] = deletion_requested.emit.bind(page)
	actions["Play from here"] = play_requested.emit.bind(page, entry.event)
	return actions

## Everything in the file pointing at the page goes back instead
func _delete_page(entry: AdventureEventOverview.Entry, page: AdventurePage) -> void:
	var file: Resource = _file_for(null, page, entry)
	if not file is AdventurePage: return
	var changes: Array[Array] = [ ]
	for reference: Array in AdventureEventEditing.find_references_to(file as AdventurePage, page): changes.append([reference[0], reference[1], null])
	changes_requested.emit(changes, "Delete %s" % AdventureGraph.get_title(page), file)

func _add_exit(entry: AdventureEventOverview.Entry, location: AdventureLocation, at: Vector2) -> GraphNode:
	var node: GraphNode = _add_node(_key(entry, location), location, AdventureGraph.get_title(location), _make_label("Location (double-click: map)"), at)
	node.modulate = FADED
	node.set_slot(0, true, 0, Color.WHITE, false, 0, Color.WHITE)
	_open_on_double_click(node, location)
	_remember(node, entry, null, [ ], [Target.PAGE, location])
	return node

## Its own host (always), the special nodes placed from the sidebar, and a "Previous location" if something leads there but none is placed
func _add_specials(entry: AdventureEventOverview.Entry, at: Vector2) -> void:
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

## Its links go to the graph's own special node again
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

## Special nodes dragged in from the sidebar ([AdventureSpecialButton]) land where they are dropped
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
	if _overview == null or _overview.entries.is_empty(): return
	var prefix: String = "%s%s/" % [_placed_prefix(_overview.entries[0]), (data as Dictionary)["adventure_special"]]
	var index: int = 0
	while layout.positions.has(prefix + str(index)): index += 1
	layout.positions[prefix + str(index)] = at
	layout_changed.emit()
	show_event(get_event(), _host)

func _open_on_double_click(node: GraphNode, location: AdventurePage) -> void:
	if location == null: return
	node.gui_input.connect(func(input: InputEvent) -> void:
		var click: InputEventMouseButton = input as InputEventMouseButton
		if click != null and click.double_click: call_after_release(exit_opened.emit.bind(location))
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

func _on_event_card_pressed(event: AdventureEvent, _page: AdventurePage) -> void: event_opened.emit(event, null)

func _key(entry: AdventureEventOverview.Entry, resource: Resource) -> String:
	return AdventureLayout.get_event_key(_overview.root, entry.event, AdventureLayout.get_key(resource))

## The graph's own special node of [param kind]
func _special_key(entry: AdventureEventOverview.Entry, kind: Target) -> String:
	return AdventureLayout.get_event_key(_overview.root, entry.event, SPECIALS[kind][0])

## Keys of special nodes placed from the sidebar start with this, then "<kind>/<number>"
func _placed_prefix(entry: AdventureEventOverview.Entry) -> String:
	return AdventureLayout.get_placed_special_prefix(_overview.root, entry.event)

func _key_of_node(node_name: StringName) -> String:
	for key: String in _nodes: if _nodes[key].name == node_name: return key
	return ""
