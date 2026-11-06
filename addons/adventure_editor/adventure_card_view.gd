@tool
@abstract
class_name AdventureCardView
extends AdventureGraphView

## Cards of the event view: a page's decisions as cards (a choice with its port, a fight or save with a port per outcome; ▲ ▼ ✕, click → Inspector),
## the add bar, and tags for conditions and effects. Edits are only requested; [AdventureEditor] makes them. [param file]: the file the change is stored in

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
## The event shown and its pages
var _event: AdventureEvent
var _pages: AdventureEventGraph
var _selected: AdventureDecision
var _card_styles: Dictionary[AdventureDecision, StyleBoxFlat] = {}
## Tags of conditions and effects, the page or event a condition is on, and the fight cards with their pages, for the dotted lines
var _tags: Dictionary[Resource, Control] = {}
var _tag_owners: Dictionary[Resource, AdventureEvent] = {}
var _fight_cards: Dictionary[AdventureDecision, Control] = {}
var _fight_pages: Dictionary[AdventureDecision, AdventurePage] = {}
## The read-only "→ beaten" chips of won fights against the encounter's own monster
var _beaten_chips: Array[Control] = [ ]
## The "+ effect" buttons, shown while the mouse is over their page ([method _show_hovered_adds])
var _hover_adds: Array[Button] = [ ]

func setup() -> void:
	super()
	node_selected.connect(func(_node: Node) -> void: _select_card(null))
	get_tree().process_frame.connect(_show_hovered_adds)
	tree_exiting.connect(func() -> void: get_tree().process_frame.disconnect(_show_hovered_adds))

## "+ effect" only on the page the mouse is over: elsewhere it's hidden but keeps its place, so nodes don't change size
func _show_hovered_adds() -> void:
	var mouse: Vector2 = get_global_mouse_position()
	for add: Button in _hover_adds:
		if not is_instance_valid(add): continue
		var node: Control = add.get_parent()
		while node != null and not node is GraphNode: node = node.get_parent() as Control
		var shown: bool = node != null and node.get_global_rect().has_point(mouse)
		add.modulate.a = 1.0 if shown else 0.0
		add.mouse_filter = Control.MOUSE_FILTER_STOP if shown else Control.MOUSE_FILTER_IGNORE

## A choice: one card with its port. A fight or save: a card with its kind and text, then a row with a port per outcome.
func _add_decision_cards(node: GraphNode, page: AdventurePage, index: int, outlet: AdventureEventGraph.Outlet) -> void:
	var decision: AdventureDecision = outlet.decision
	if not outlet.to_check:
		var text: String = _describe_outlet(outlet)
		var icon: Texture2D = null
		if decision is AdventureLootDecision:
			text = "%s\n%s" % [describe_loot(decision as AdventureLootDecision, _get_encounter()), text]
			icon = _get_editor_icon("Search")
		var card: PanelContainer = _make_card(page, index, text, Color.TRANSPARENT, icon, outlet.goes_back())
		card.get_child(0).add_child(_make_tags(decision, &"consequences", _file_for(decision, page), "effect", _get_effect_additions))
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
	var check: String = AdventureEventGraph.describe_check(decision)
	var monster: MonsterProfile = tooltips.fight_odds.get_monster_of(decision as AdventureFightDecision) if is_fight and tooltips != null and tooltips.fight_odds != null else null
	if monster != null: check = "Fight: %s" % monster.name
	var check_card: PanelContainer = _make_card(page, index, "%s\n%s" % [check, decision.description.get_slice("\n", 0)], color, icon, false)
	if is_fight:
		_fight_cards[decision] = check_card
		_add_odds(check_card, decision as AdventureFightDecision)
	node.add_child(check_card)
	for outcome: AdventureEventGraph.Outlet in AdventureEventGraph.get_outcomes(decision):
		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_END
		if not outcome.consequences_property.is_empty(): row.add_child(_make_tags(decision, outcome.consequences_property, _file_for(decision, page), "effect", _get_effect_additions))
		var label: Label = Label.new()
		label.text = _describe_outlet(outcome)
		if outcome.goes_back(): label.modulate = FADED
		row.add_child(label)
		node.add_child(row)
		if is_fight and outcome.label == "Won": _add_beaten_chip(row, decision as AdventureFightDecision)
		node.set_slot(node.get_child_count() - 1, false, 0, Color.WHITE, true, 0, OUTCOME_COLORS.get(outcome.label, color))

## How often the Fight Lab's reference fighters win against the fight's monster, with their best approach ("Weak 12% · Average 48% · Strong 91%", faded and marked when
## out of date; the card's tooltip tells more), and a button running them in the lab
func _add_odds(card: PanelContainer, fight: AdventureFightDecision) -> void:
	var fight_odds: AdventureFightOdds = tooltips.fight_odds if tooltips != null else null
	var monster: MonsterProfile = fight_odds.get_monster_of(fight) if fight_odds != null else null
	if monster == null: return
	var parts: Array[String] = []
	# Each fighter with its best approach; the tooltip compares them
	for best: Dictionary in AdventureFightOdds.get_best(fight_odds.get_odds(fight)):
		parts.append("%s %d%%" % [best["name"], roundi(AdventureFightOdds.get_won(best) * 100.0)])
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label: Label = _make_info(" · ".join(parts) if not parts.is_empty() else "Fight odds: not simulated")
	if fight_odds.is_out_of_date(fight): label.text += " (out of date)"
	elif not parts.is_empty(): label.modulate = Color.WHITE
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	if AdventureFightOdds.has_lab():
		row.add_child(AdventureUi.icon_button("ExternalLink", "⚔", "Open in the Fight Lab: the reference fighters against %s" % monster.name, AdventureFightOdds.open_in_lab.bind(monster)))
	card.get_child(0).add_child(row)

## "Loot: Lurker" (the named encounter, else [param own], the one whose events are shown)
static func describe_loot(loot: AdventureLootDecision, own: AdventureEncounter) -> String:
	var looted: AdventureEncounter = loot.get_looted(own)
	return "Loot: %s" % (looted.title if looted != null else AdventureStageCondition.name_subject(loot.encounter) if not loot.encounter.is_empty() else "its encounter")

## Winning a fight against the encounter's own monster beats it: no effect does that, the fight does, so the chip can't be removed
func _add_beaten_chip(row: HBoxContainer, fight: AdventureFightDecision) -> void:
	var encounter: AdventureEncounter = _get_encounter()
	if encounter == null or not encounter.profile is MonsterProfile or not fight.enemies.is_empty() or not _is_own(fight.encounter, encounter): return
	var chip: Label = _make_info("→ beaten")
	chip.tooltip_text = "Winning beats its monster (the fight does it)"
	row.add_child(chip)
	row.move_child(chip, 0)
	_beaten_chips.append(chip)

static func _is_own(subject: String, encounter: AdventureEncounter) -> bool:
	return subject.is_empty() or Files.load_existing(subject) == encounter

## Clicking it edits the decision in the Inspector; ▲ ▼ move it, ✕ removes it
func _make_card(page: AdventurePage, index: int, text: String, color: Color, icon: Texture2D, faded: bool) -> PanelContainer:
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
	if index > 0: row.add_child(AdventureUi.icon_button("MoveUp", "▲", "Move up", _move_decision.bind(page, index, -1)))
	if index < count - 1: row.add_child(AdventureUi.icon_button("MoveDown", "▼", "Move down", _move_decision.bind(page, index, 1)))
	row.add_child(AdventureUi.icon_button("Remove", "✕", "Remove", _remove_decision.bind(page, index)))
	lines.add_child(row)
	card.add_child(lines)
	# After its lines, which stay the card's first child for the tags and odds added to them
	if tooltips != null: tooltips.attach(card, decision, "edit it in the Inspector")
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
		if tooltips != null and (item is AdventureStageCondition or item is AdventureStageConsequence): tooltips.attach(tag, item, "edit it in the Inspector")
		tags.add_child(tag)
		_tags[item] = tag
		var without: Array = items.duplicate()
		without.remove_at(index)
		tags.add_child(AdventureUi.icon_button("Remove", "✕", "Remove", _request.bind(resource, property, without, "Remove %s" % tag.text, file)))
	var add: Button = AdventureUi.icon_button("Add", "+", "Add a %s" % add_text, func() -> void:
		var actions: Dictionary[String, Callable] = {}
		var additions: Dictionary[String, Resource] = get_additions.call()
		for text: String in additions:
			actions[text] = func() -> void:
				var with: Array = items.duplicate()
				with.append(additions[text])
				_request(resource, property, with, "Add %s" % text, file)
		_show_menu(actions)
	)
	add.text = add_text
	tags.add_child(add)
	if add_text == "effect": _hover_adds.append(add)
	return tags

func _get_effect_additions() -> Dictionary[String, Resource]:
	var additions: Dictionary[String, Resource] = {}
	var types: Dictionary[String, Script] = AdventureMakers.get_consequence_types()
	for type_name: String in types: additions[AdventureMakers.get_type_name(type_name)] = AdventureMakers.make_consequence(types[type_name])
	return additions

## Every kind of condition, "It can fight / is beaten / is dead" for a monster encounter, and "is …" for each stage of the event's encounter
func _get_condition_additions(_holder: AdventureEvent) -> Dictionary[String, Resource]:
	var additions: Dictionary[String, Resource] = {}
	var encounter: AdventureEncounter = _get_encounter()
	if encounter != null and encounter.profile is MonsterProfile:
		for state: AdventureMonsterCondition.State in AdventureMonsterCondition.STATE_TEXTS:
			var condition: AdventureMonsterCondition = AdventureMakers.make_monster_condition(state)
			additions[condition.describe()] = condition
	if encounter != null:
		for track: AdventureStageTrack in encounter.tracks:
			if track == null: continue
			for stage: String in track.stages: additions["%s is %s" % [track.name, stage]] = AdventureMakers.make_stage_condition(track.name, stage)
	var types: Dictionary[String, Script] = AdventureMakers.get_condition_types()
	for type_name: String in types: additions[AdventureMakers.get_type_name(type_name)] = AdventureMakers.make_condition(types[type_name])
	return additions

## The encounter whose events are shown, if any
func _get_encounter() -> AdventureEncounter: return null

## Its own text, or its kind's name when it has none to show
static func _describe(item: Resource) -> String:
	var text: String = item.call(&"describe")
	return text if not text.is_empty() else AdventureMakers.get_type_name(item.get_script().get_global_name())

## One "Add" button for new choices, fights, saves and searches, from a menu with their icons
func _make_add_bar(page: AdventurePage) -> HBoxContainer:
	var bar: HBoxContainer = HBoxContainer.new()
	var add: Button = AdventureUi.text_button("Add", "Add", "A new choice, fight, save or search on this page", func() -> void: _show_menu(_get_add_actions(page)))
	add.flat = true
	bar.add_child(add)
	return bar

func _get_add_actions(page: AdventurePage) -> Dictionary[String, Callable]:
	return {
		"Add choice": _add_decision.bind(page, AdventureMakers.make_choice),
		"Add fight": _add_decision.bind(page, AdventureMakers.make_fight),
		"Add save": _add_decision.bind(page, AdventureMakers.make_save),
		"Add loot (search)": _add_decision.bind(page, AdventureMakers.make_loot),
	}

## Fights and saves get the game's icons
func _get_menu_icon(text: String) -> Texture2D:
	var lower: String = text.to_lower()
	if lower.contains("fight") or lower.contains("is beaten") or lower.contains("is dead") or lower.begins_with("kill"): return FIGHT_ICON
	if lower.contains("save"): return SAVE_ICON
	if lower.contains("loot"): return _get_editor_icon("Search")
	return super(text)

func _add_decision(page: AdventurePage, make: Callable) -> void:
	var decisions: Array[AdventureDecision] = page.decisions.duplicate()
	var decision: AdventureDecision = make.call()
	decisions.append(decision)
	_request(page, &"decisions", decisions, "Add %s" % decision.description, _file_for(null, page))

func _move_decision(page: AdventurePage, index: int, step: int) -> void:
	var decisions: Array[AdventureDecision] = page.decisions.duplicate()
	var decision: AdventureDecision = decisions.pop_at(index)
	decisions.insert(index + step, decision)
	_request(page, &"decisions", decisions, "Move %s" % decision.description, _file_for(decision, page))

## Refused if a page stored inside the file would be lost with it
func _remove_decision(page: AdventurePage, index: int) -> void:
	var decision: AdventureDecision = page.decisions[index]
	var file: Resource = _file_for(decision, page)
	var references: Array[AdventurePageReference] = [ ]
	references.assign(decision.get_page_references())
	if file is AdventurePage and AdventureEventEditing.would_lose_page(file as AdventurePage, references):
		push_warning("\"%s\" is the only way to a page stored in this file; delete that page first (right-click it)" % decision.description)
		return
	var decisions: Array[AdventureDecision] = page.decisions.duplicate()
	decisions.remove_at(index)
	_request(page, &"decisions", decisions, "Remove %s" % decision.description, file)

## The file a change of [param decision] (or of [param page]) is stored in: the first of them stored somewhere already, else the event's
func _file_for(decision: AdventureDecision, page: AdventurePage) -> Resource:
	for resource: Resource in [decision, page, _event]:
		if resource != null and not resource.resource_path.is_empty(): return load(AdventureEventEditing.get_file_path(resource))
	return null

func _make_condition_tags(holder: AdventureEvent, file: Resource) -> HFlowContainer:
	var tags: HFlowContainer = _make_tags(holder, &"conditions", file, "condition", _get_condition_additions.bind(holder))
	for condition: AdventureCondition in holder.conditions: if condition != null: _tag_owners[condition] = holder
	return tags

static func _describe_outlet(outlet: AdventureEventGraph.Outlet) -> String:
	if not outlet.goes_back(): return outlet.label
	var steps: int = outlet.get_back_steps()
	return "%s (back%s)" % [outlet.label, " %d" % steps if steps > 1 else ""]
