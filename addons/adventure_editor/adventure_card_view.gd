@tool
@abstract
class_name AdventureCardView
extends AdventureGraphView

## Cards of the event view: a page's decisions as cards (a choice with its port, a fight or save with a port per outcome; ▲ ▼ ✕, click → Inspector),
## the add bar, and tags for conditions and effects. Edits are only requested; [AdventureEditor] makes them. [param file]: the file the change is stored in

signal decisions_requested(page: AdventurePage, decisions: Array[AdventureDecision], file: Resource, action: String)
signal property_requested(resource: Resource, property: StringName, value: Variant, file: Resource, action: String)

const FIGHT_COLOR: Color = Color(0.85, 0.3, 0.25)
const SAVE_COLOR: Color = Color(0.45, 0.6, 0.9)
const HOST_COLOR: Color = Color(0.35, 0.8, 0.7)
const CARD_ALPHA: float = 0.18
const FIGHT_ICON: Texture2D = preload("uid://co8bcva1h1plg")  # ancient-sword.svg
const SAVE_ICON: Texture2D = preload("uid://dpmwlpo7a7q1r")  # rolling-dices.svg
const HOST_ICON: Texture2D = preload("uid://bee2desykk34h")  # anticlockwise-rotation.svg
## Outcome ports and their links by outcome
const OUTCOME_COLORS: Dictionary[String, Color] = {
	"Won": Color(0.45, 0.8, 0.4), "Success": Color(0.45, 0.8, 0.4),
	"Lost": Color(0.9, 0.35, 0.3), "Failure": Color(0.9, 0.35, 0.3),
	"Fled": Color(0.95, 0.8, 0.3), "Draw": Color(0.6, 0.6, 0.6),
}
const SELECTED_COLOR: Color = Color(1, 1, 1, 0.9)

## The decision whose card was clicked; each card's style, to show it
var _selected: AdventureDecision
var _card_styles: Dictionary[AdventureDecision, StyleBoxFlat] = {}
## Tags of conditions and effects, the page or event a condition is on, and the fight cards with their pages, for the dotted lines
var _tags: Dictionary[Resource, Control] = {}
var _tag_owners: Dictionary[Resource, AdventurePage] = {}
var _fight_cards: Dictionary[AdventureDecision, Control] = {}
var _fight_pages: Dictionary[AdventureDecision, AdventurePage] = {}

func setup() -> void:
	super()
	node_selected.connect(func(_node: Node) -> void: _select_card(null))

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
	var attribute: CharacterAttribute = (decision as AdventureSaveDecision).attribute if decision is AdventureSaveDecision else null
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
		var enemies: Array[MonsterProfile] = (fight as AdventureFightDecision).enemies
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
			if _fight_pages[fight] == spawning and (fight as AdventureFightDecision).enemies.has(condition.monster.monster): _add_dashed(_tags[item], _fight_cards[fight], FIGHT_COLOR)

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

## Fights, saves and monsters get the game's icons
func _get_menu_icon(text: String) -> Texture2D:
	var lower: String = text.to_lower()
	if lower.contains("fight") or lower.contains("is beaten") or lower.contains("is dead"): return FIGHT_ICON
	if lower.contains("save"): return SAVE_ICON
	return super(text)

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
	references.assign(decision.get_page_references())
	if file is AdventurePage and AdventureEventEditing.would_lose_page(file as AdventurePage, references):
		push_warning("\"%s\" is the only way to a page stored in this file; delete that page first (right-click it)" % decision.description)
		return
	var decisions: Array[AdventureDecision] = page.decisions.duplicate()
	decisions.remove_at(index)
	decisions_requested.emit(page, decisions, file, "Remove %s" % decision.description)

## The file a change of [param decision] (or of [param page]) is stored in: the first of them stored somewhere already, else the event's
func _file_for(decision: AdventureDecision, page: AdventurePage, entry: AdventureEventOverview.Entry) -> Resource:
	for resource: Resource in [decision, page, entry.event]:
		if resource != null and not resource.resource_path.is_empty(): return load(AdventureEventEditing.get_file_path(resource))
	return null

func _make_condition_tags(owner: AdventurePage, file: Resource) -> HFlowContainer:
	var tags: HFlowContainer = _make_tags(owner, &"conditions", file, "condition", _get_condition_additions.bind(owner))
	for condition: AdventureCondition in owner.conditions: if condition != null: _tag_owners[condition] = owner
	return tags

static func _describe_outlet(outlet: AdventureEventGraph.Outlet) -> String:
	if not outlet.goes_back(): return outlet.label
	var steps: int = outlet.get_back_steps()
	return "%s (back%s)" % [outlet.label, " %d" % steps if steps > 1 else ""]
