@tool
class_name AdventureEventView
extends AdventureGraphView

## One event at a glance ([AdventureEventOverview]): a frame per event (a scenario: per option) and per sub-event, each with the pages behind it,
## special nodes ("Host", "Previous location": one host per frame always, more dragged in from the sidebar) and the locations it leads to; sub-events hang dashed from the page listing them.
## A page's card holds its decisions as cards: a choice with its port, a fight or save with a port per outcome.
## Edits are only requested here; [AdventureEditor] makes them (undo, saving). [param file]: the file the change is stored in

## An exit or the picked host was double-clicked
signal exit_opened(location: AdventurePage)
signal reference_requested(decision: AdventureDecision, property: StringName, reference: AdventurePageReference, file: Resource)
signal decisions_requested(page: AdventurePage, decisions: Array[AdventureDecision], file: Resource, action: String)
## Each [decision, property] is set to none
signal references_cleared(references: Array[Array], file: Resource, action: String)
signal property_requested(resource: Resource, property: StringName, value: Variant, file: Resource, action: String)
## A new event as an option of [param scenario]
signal option_requested(scenario: AdventureEventScenario)

enum Target { PAGE, HOST, PREVIOUS }

const FIGHT_COLOR: Color = Color(0.85, 0.3, 0.25)
const SAVE_COLOR: Color = Color(0.45, 0.6, 0.9)
const HOST_COLOR: Color = Color(0.35, 0.8, 0.7)
const PREVIOUS_COLOR: Color = Color(0.7, 0.55, 0.95)
const CARD_ALPHA: float = 0.18
const FIGHT_ICON: Texture2D = preload("uid://co8bcva1h1plg")  # ancient-sword.svg
const SAVE_ICON: Texture2D = preload("uid://dpmwlpo7a7q1r")  # rolling-dices.svg
const HOST_ICON: Texture2D = preload("uid://bee2desykk34h")  # anticlockwise-rotation.svg
const PREVIOUS_ICON: Texture2D = preload("uid://dmkjss474288g")  # exit-door.svg
## Special nodes by kind: [name in layout keys and drag data, title, hint, color, icon]
const SPECIALS: Dictionary[Target, Array] = {
	Target.HOST: ["host", "Host", "Back to the page the event is on", HOST_COLOR, HOST_ICON],
	Target.PREVIOUS: ["previous", "Previous location", "Back to where the player was before the host", PREVIOUS_COLOR, PREVIOUS_ICON],
}
## Where a default "Previous location" sits below the host
const SPECIAL_SPACING: float = 140.0
const ICON_SIZE: int = 16
## Outcome ports and their links by outcome
const OUTCOME_COLORS: Dictionary[String, Color] = {
	"Won": Color(0.45, 0.8, 0.4), "Success": Color(0.45, 0.8, 0.4),
	"Lost": Color(0.9, 0.35, 0.3), "Failure": Color(0.9, 0.35, 0.3),
	"Fled": Color(0.95, 0.8, 0.3), "Draw": Color(0.6, 0.6, 0.6),
}
const SELECTED_COLOR: Color = Color(1, 1, 1, 0.9)
const NODE_GAP: float = 40.0

var _overview: AdventureEventOverview
## The host picked to see the event at; none: any host
var _host: AdventurePage
## By node name: the entry, the page whose decisions it shows, what its output ports lead to, and what a link onto it leads to ([Target, page])
var _node_entries: Dictionary[StringName, AdventureEventOverview.Entry] = {}
var _node_pages: Dictionary[StringName, AdventurePage] = {}
var _node_ports: Dictionary[StringName, Array] = {}
var _node_targets: Dictionary[StringName, Array] = {}
## The decision whose card was clicked; each card's style, to show it
var _selected: AdventureDecision
var _card_styles: Dictionary[AdventureDecision, StyleBoxFlat] = {}
var _frame_entries: Dictionary[GraphFrame, AdventureEventOverview.Entry] = {}
## Tags of conditions and effects, the page or event a condition is on, and the fight cards with their pages, for the dotted lines
var _tags: Dictionary[Resource, Control] = {}
var _tag_owners: Dictionary[Resource, AdventurePage] = {}
var _fight_cards: Dictionary[AdventureDecision, Control] = {}
var _fight_pages: Dictionary[AdventureDecision, AdventurePage] = {}
## [nodes, top] per column placed by default, stacked once laid out; showing again drops them with the nodes
var _unstacked: Array[Array] = [ ]

func setup() -> void:
	super()
	right_disconnects = true
	connection_request.connect(_on_connection_request)
	disconnection_request.connect(func(from: StringName, port: int, _to: StringName, _to_port: int) -> void: _request_reference(from, port, null))
	connection_to_empty.connect(_on_connection_to_empty)
	node_selected.connect(func(_node: Node) -> void: _select_card(null))

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
		node.add_child(_make_info("Turn back. (automatic, back 1; link it to continue elsewhere)"))
		node.set_slot(node.get_child_count() - 1, false, 0, Color.WHITE, true, 0, FADED)
	node.add_child(_make_add_bar(entry, page))
	_remember(node, entry, page, ports, [Target.PAGE, page])
	_on_right_click(node, func() -> Dictionary[String, Callable]: return _get_page_actions(entry, page), _get_menu_icons())
	return node

## A choice: one card with its port. A fight or save: a card with its kind and text, then a row with a port per outcome.
func _add_decision_cards(node: GraphNode, entry: AdventureEventOverview.Entry, page: AdventurePage, index: int, outlet: AdventureEventGraph.Outlet) -> void:
	var decision: AdventureDecision = outlet.decision
	if not outlet.to_check:
		var card: PanelContainer = _make_card(entry, page, index, _describe_outlet(outlet), Color.TRANSPARENT, null, outlet.goes_back())
		card.get_child(0).add_child(_make_tags(decision, &"consequences", _file_for(decision, page, entry), "effect", _get_effect_additions))
		node.add_child(card)
		node.set_slot(node.get_child_count() - 1, false, 0, Color.WHITE, true, 0, Color.WHITE)
		return
	var is_fight: bool = decision is AdventureFightDecision
	var color: Color = FIGHT_COLOR if is_fight else SAVE_COLOR
	var icon: Texture2D = FIGHT_ICON if is_fight else SAVE_ICON
	var attribute: CharacterAttribute = decision.get(&"attribute") as CharacterAttribute if decision is AdventureSaveDecision else null
	if attribute != null:
		color = attribute.color
		if attribute.icon != null: icon = attribute.icon
	var check_card: PanelContainer = _make_card(entry, page, index, "%s\n%s" % [AdventureEventGraph.describe_check(decision), decision.description.get_slice("\n", 0)], color, icon, false)
	if is_fight: _fight_cards[decision] = check_card
	node.add_child(check_card)
	for outcome: AdventureEventGraph.Outlet in AdventureEventGraph.get_outcomes(decision):
		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		if not outcome.consequences_property.is_empty(): row.add_child(_make_tags(decision, outcome.consequences_property, _file_for(decision, page, entry), "effect", _get_effect_additions))
		var label: Label = Label.new()
		label.text = _describe_outlet(outcome)
		if outcome.goes_back(): label.modulate = FADED
		row.add_child(label)
		node.add_child(row)
		node.set_slot(node.get_child_count() - 1, false, 0, Color.WHITE, true, 0, OUTCOME_COLORS.get(outcome.label, color))

## Clicking it edits the decision in the Inspector; ▲ ▼ move it, ✕ removes it
func _make_card(entry: AdventureEventOverview.Entry, page: AdventurePage, index: int, text: String, color: Color, icon: Texture2D, faded: bool) -> PanelContainer:
	var decision: AdventureDecision = page.decisions[index]
	var card: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(color, CARD_ALPHA) if color != Color.TRANSPARENT else Color(1, 1, 1, 0.05)
	style.border_width_left = 3
	style.border_color = color if color != Color.TRANSPARENT else Color(1, 1, 1, 0.2)
	style.set_content_margin_all(4)
	card.add_theme_stylebox_override(&"panel", style)
	style.set_meta(&"border", style.border_color)
	_card_styles[decision] = style
	if decision == _selected: _style_card(style, true)
	card.tooltip_text = "Click: edit in the Inspector"
	card.gui_input.connect(func(input: InputEvent) -> void:
		var click: InputEventMouseButton = input as InputEventMouseButton
		if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_select_card(decision)
			EditorInterface.edit_resource(decision)
			accept_event()
	)
	var lines: VBoxContainer = VBoxContainer.new()
	lines.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if icon != null: row.add_child(_make_icon(icon, color))
	var label: Label = _make_label(text)
	label.custom_minimum_size.x = THUMBNAIL_SIZE.x - 3 * ICON_SIZE - 24
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if faded: label.modulate = FADED
	row.add_child(label)
	var count: int = page.decisions.size()
	if index > 0: row.add_child(_make_tool_button("MoveUp", "▲", "Move up", _move_decision.bind(entry, page, index, -1)))
	if index < count - 1: row.add_child(_make_tool_button("MoveDown", "▼", "Move down", _move_decision.bind(entry, page, index, 1)))
	row.add_child(_make_tool_button("Remove", "✕", "Remove", _remove_decision.bind(entry, page, index)))
	lines.add_child(row)
	card.add_child(lines)
	return card

## Shows which decision's card was clicked last (none: no card)
func _select_card(decision: AdventureDecision) -> void:
	if _card_styles.has(_selected): _style_card(_card_styles[_selected], false)
	_selected = decision
	if _card_styles.has(decision): _style_card(_card_styles[decision], true)

func _style_card(style: StyleBoxFlat, selected: bool) -> void:
	style.set_border_width_all(2 if selected else 0)
	style.border_width_left = 3
	style.border_color = SELECTED_COLOR if selected else style.get_meta(&"border")

## Tags for the resources in [param resource]'s [param property] (click: Inspector, ✕: removes) and a button adding one of [param get_additions] (text -> a made resource), asked when it is pressed
func _make_tags(resource: Resource, property: StringName, file: Resource, add_text: String, get_additions: Callable) -> HFlowContainer:
	var tags: HFlowContainer = HFlowContainer.new()
	var items: Array = resource.get(property)
	for index: int in items.size():
		var item: Resource = items[index]
		if item == null: continue
		var tag: Button = Button.new()
		tag.text = _describe(item)
		tag.tooltip_text = "Edit in the Inspector"
		tag.pressed.connect(func() -> void: EditorInterface.edit_resource(item))
		tags.add_child(tag)
		_tags[item] = tag
		var without: Array = items.duplicate()
		without.remove_at(index)
		tags.add_child(_make_tool_button("Remove", "✕", "Remove", property_requested.emit.bind(resource, property, without, file, "Remove %s" % tag.text)))
	var add: Button = _make_tool_button("Add", "+", "Add a %s" % add_text, func() -> void:
		var actions: Dictionary[String, Callable] = {}
		var additions: Dictionary[String, Resource] = get_additions.call()
		for text: String in additions:
			actions[text] = func() -> void:
				var with: Array = items.duplicate()
				with.append(additions[text])
				property_requested.emit(resource, property, with, file, "Add %s" % text)
		_show_menu(actions)
	)
	add.text = add_text
	tags.add_child(add)
	return tags

func _get_effect_additions() -> Dictionary[String, Resource]:
	var additions: Dictionary[String, Resource] = {}
	var types: Dictionary[String, Script] = AdventureEventEditing.get_consequence_types()
	for type_name: String in types: additions[AdventureEventEditing.get_type_name(type_name)] = AdventureEventEditing.make_consequence(types[type_name])
	return additions

## Every kind of condition, and "can fight / is beaten / is dead" for each monster of the fights shown
func _get_condition_additions(owner: AdventurePage) -> Dictionary[String, Resource]:
	var additions: Dictionary[String, Resource] = {}
	for fight: AdventureDecision in _fight_pages:
		var enemies: Array = fight.get(&"enemies")
		for enemy_index: int in enemies.size():
			var monster: MonsterProfile = enemies[enemy_index]
			if monster == null: continue
			var index: int = enemies.slice(0, enemy_index).count(monster)
			for state: AdventureMonsterCondition.State in AdventureMonsterCondition.STATE_TEXTS:
				var condition: AdventureMonsterCondition = AdventureEventEditing.make_monster_condition(state, monster, index, _fight_pages[fight], owner)
				if condition != null: additions[condition.describe() + (" %d" % (index + 1) if index > 0 else "")] = condition
	var types: Dictionary[String, Script] = AdventureEventEditing.get_condition_types()
	for type_name: String in types: additions[AdventureEventEditing.get_type_name(type_name)] = AdventureEventEditing.make_condition(types[type_name])
	return additions

## Its own text, or its kind's name when it has none to show
static func _describe(item: Resource) -> String:
	var text: String = item.call(&"describe")
	return text if not text.is_empty() else AdventureEventEditing.get_type_name(item.get_script().get_global_name())

## Monster conditions point dotted at the fight card spawning their monster
func _add_condition_lines() -> void:
	for item: Resource in _tags:
		var condition: AdventureMonsterCondition = item as AdventureMonsterCondition
		if condition == null or condition.monster == null: continue
		var owner: AdventurePage = _tag_owners.get(condition)
		var spawning: AdventurePage = condition.monster.spawned_by.get_adventure_page() if condition.monster.spawned_by != null else owner
		for fight: AdventureDecision in _fight_pages:
			if _fight_pages[fight] == spawning and (fight.get(&"enemies") as Array).has(condition.monster.monster): _add_dashed(_tags[item], _fight_cards[fight], FIGHT_COLOR)

## Buttons for new choices, fights and saves
func _make_add_bar(entry: AdventureEventOverview.Entry, page: AdventurePage) -> HBoxContainer:
	var bar: HBoxContainer = HBoxContainer.new()
	var actions: Dictionary[String, Callable] = _get_add_actions(entry, page)
	var icons: Dictionary[String, Texture2D] = _get_add_icons()
	for text: String in actions:
		var button: Button = Button.new()
		button.text = text.trim_prefix("Add ")
		button.icon = icons[text]
		button.add_theme_constant_override(&"icon_max_width", ICON_SIZE)
		button.tooltip_text = text
		button.pressed.connect(actions[text])
		bar.add_child(button)
	return bar

func _get_add_actions(entry: AdventureEventOverview.Entry, page: AdventurePage) -> Dictionary[String, Callable]:
	return {
		"Add choice": _add_decision.bind(entry, page, AdventureEventEditing.make_choice),
		"Add fight": _add_decision.bind(entry, page, AdventureEventEditing.make_fight),
		"Add save": _add_decision.bind(entry, page, AdventureEventEditing.make_save),
	}

func _get_add_icons() -> Dictionary[String, Texture2D]:
	return {"Add choice": _get_editor_icon("Add"), "Add fight": FIGHT_ICON, "Add save": SAVE_ICON}

## Adding decisions, and deleting pages stored inside the file (nothing else deletes them, so links can't lose them by accident)
func _get_page_actions(entry: AdventureEventOverview.Entry, page: AdventurePage) -> Dictionary[String, Callable]:
	var actions: Dictionary[String, Callable] = _get_add_actions(entry, page)
	if page != entry.event and AdventureEventEditing.is_inside_file(page): actions["Delete page"] = _delete_page.bind(entry, page)
	return actions

func _get_menu_icons() -> Dictionary[String, Texture2D]:
	var icons: Dictionary[String, Texture2D] = _get_add_icons()
	icons["Delete page"] = _get_editor_icon("Remove")
	return icons

func _add_decision(entry: AdventureEventOverview.Entry, page: AdventurePage, make: Callable) -> void:
	var decisions: Array[AdventureDecision] = page.decisions.duplicate()
	var decision: AdventureDecision = make.call()
	decisions.append(decision)
	decisions_requested.emit(page, decisions, _file_for(null, page, entry), "Add %s" % decision.description)

func _move_decision(entry: AdventureEventOverview.Entry, page: AdventurePage, index: int, step: int) -> void:
	var decisions: Array[AdventureDecision] = page.decisions.duplicate()
	var decision: AdventureDecision = decisions.pop_at(index)
	decisions.insert(index + step, decision)
	decisions_requested.emit(page, decisions, _file_for(decision, page, entry), "Move %s" % decision.description)

## Refused if a page stored inside the file would be lost with it
func _remove_decision(entry: AdventureEventOverview.Entry, page: AdventurePage, index: int) -> void:
	var decision: AdventureDecision = page.decisions[index]
	var file: Resource = _file_for(decision, page, entry)
	var references: Array[AdventurePageReference] = [ ]
	references.assign(AdventureGraph.get_references(decision).values())
	if file is AdventurePage and AdventureEventEditing.would_lose_page(file as AdventurePage, references):
		push_warning("\"%s\" is the only way to a page stored in this file; delete that page first (right-click it)" % decision.description)
		return
	var decisions: Array[AdventureDecision] = page.decisions.duplicate()
	decisions.remove_at(index)
	decisions_requested.emit(page, decisions, file, "Remove %s" % decision.description)

## Everything in the file pointing at the page goes back instead
func _delete_page(entry: AdventureEventOverview.Entry, page: AdventurePage) -> void:
	var file: Resource = _file_for(null, page, entry)
	if file is AdventurePage: references_cleared.emit(AdventureEventEditing.find_references_to(file as AdventurePage, page), file, "Delete %s" % AdventureGraph.get_title(page))

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
	if removable: _on_right_click(node, func() -> Dictionary[String, Callable]: return {"Remove": _remove_special.bind(key)}, {"Remove": _get_editor_icon("Remove")})
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
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data as Dictionary).has("adventure_special")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var at: Vector2 = _to_graph(at_position)
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
		decisions_requested.emit(page, decisions, file, "Continue")
		return
	var old: AdventurePageReference = outlet.decision.get(outlet.property) as AdventurePageReference
	if old != null and old != reference and file is AdventurePage and AdventureEventEditing.would_lose_page(file as AdventurePage, [old]):
		push_warning("Only \"%s\" leads to %s, which is stored in this file; delete that page instead (right-click it)" % [outlet.label, AdventureGraph.get_title(old as AdventurePage)])
		return
	reference_requested.emit(outlet.decision, outlet.property, reference, file)

func _get_port(node_name: StringName, port: int) -> AdventureEventGraph.Outlet:
	var ports: Array = _node_ports.get(node_name, [ ])
	return ports[port] if port < ports.size() else null

## The file a change of [param decision] (or of [param page]) is stored in: the first of them stored somewhere already, else the event's
func _file_for(decision: AdventureDecision, page: AdventurePage, entry: AdventureEventOverview.Entry) -> Resource:
	for resource: Resource in [decision, page, entry.event]:
		if resource != null and not resource.resource_path.is_empty(): return load(AdventureEventEditing.get_file_path(resource))
	return null

## A sub-event's card shows its frame (a scenario: its switch); others open the event
func _on_event_card_pressed(event: AdventurePage, _page: AdventurePage) -> void:
	if _nodes.has(_switch_key(event)):
		focus_node(_nodes[_switch_key(event)])
		return
	var entry: AdventureEventOverview.Entry = _overview.get_listed_entry(event)
	if entry != null: focus_node(_nodes[_key(entry, entry.event)])
	else: event_opened.emit(event, null)

func _make_condition_tags(owner: AdventurePage, file: Resource) -> HFlowContainer:
	var tags: HFlowContainer = _make_tags(owner, &"conditions", file, "condition", _get_condition_additions.bind(owner))
	for condition: AdventureCondition in owner.conditions: if condition != null: _tag_owners[condition] = owner
	return tags

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
	property_requested.emit(scenario, &"events", options, file, "Move %s" % AdventureGraph.get_title(option))

func _remove_option(scenario: AdventureEventScenario, file: Resource, index: int) -> void:
	var options: Array[AdventurePage] = scenario.events.duplicate()
	var option: AdventurePage = options.pop_at(index)
	if AdventureEventEditing.is_inside_file(option):
		push_warning("%s is stored inside the scenario's file and would be lost" % AdventureGraph.get_title(option))
		return
	property_requested.emit(scenario, &"events", options, file, "Remove %s" % AdventureGraph.get_title(option))

func _switch_key(scenario: AdventurePage) -> String:
	return "%s/switch/%s" % [AdventureLayout.get_key(_overview.root), AdventureLayout.get_key(scenario)]

static func _describe_outlet(outlet: AdventureEventGraph.Outlet) -> String:
	if not outlet.goes_back(): return outlet.label
	var steps: int = outlet.get_back_steps()
	return "%s (back%s)" % [outlet.label, " %d" % steps if steps > 1 else ""]

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

func _key(entry: AdventureEventOverview.Entry, resource: Resource) -> String:
	return "%s/%s/%s" % [AdventureLayout.get_key(_overview.root), AdventureLayout.get_key(entry.event), AdventureLayout.get_key(resource)]

## The frame's own special node of [param kind]
func _special_key(entry: AdventureEventOverview.Entry, kind: Target) -> String:
	return "%s/%s/%s" % [AdventureLayout.get_key(_overview.root), AdventureLayout.get_key(entry.event), SPECIALS[kind][0]]

## Keys of special nodes placed from the sidebar start with this, then "<kind>/<number>"
func _placed_prefix(entry: AdventureEventOverview.Entry) -> String:
	return "%s/%s/special/" % [AdventureLayout.get_key(_overview.root), AdventureLayout.get_key(entry.event)]

func _key_of_node(node_name: StringName) -> String:
	for key: String in _nodes: if _nodes[key].name == node_name: return key
	return ""
