@tool
class_name BreathDice
extends PanelContainer

@export var character: Character : set = _set_character

@export_group("Configuration")
@export var _die_types: FlexContainer
@export var _breath_dice_group: PackedScene

var button_groups: Dictionary[DieType, BreathDiceGroup] = {}

func _ready() -> void:
	if not Engine.is_editor_hint(): return
	var debug_dice_pool: Dictionary[DieType, int] = {
		Rules.d4: 1,
		Rules.d6: 1,
		Rules.d8: 1,
		Rules.d10: 1,
		Rules.d12: 1,
	}
	var debug_breath_dice: Array[BreathDie] = DiceRoller.generate_breath_dice_pool(debug_dice_pool)
	setup_breath_dice(debug_breath_dice)

func setup_breath_dice(breath_dice: Array[BreathDie]) -> void:
	if button_groups.is_empty(): _setup_die_types()
	for die_type: DieType in button_groups.keys():
		var relevant_breath_dice: Array[BreathDie] = []
		relevant_breath_dice.assign(breath_dice.filter(func(breath_die: BreathDie) -> bool: return breath_die.die_type == die_type))
		var button_group: BreathDiceGroup = button_groups[die_type]
		button_group.breath_dice = relevant_breath_dice

func set_exhaustion(exhaustion: Array[DieType]) -> void:
	for button_group: BreathDiceGroup in button_groups.values(): button_group.exhaustion = exhaustion

func highlight(die_types: Array[DieType]) -> void:
	for die_type: DieType in button_groups.keys():
		var button_group: BreathDiceGroup = button_groups[die_type]
		if die_types.has(die_type): button_group.highlight()
		else: button_group.stop_highlighting()

func stop_highlighting() -> void:
	for button_group: BreathDiceGroup in button_groups.values(): button_group.stop_highlighting()

func _setup_die_types(die_types: Array[DieType] = Rules.BREATH_DICE) -> void:
	button_groups.clear()
	_die_types.clear()
	for die_type: DieType in die_types:
		var button_group: BreathDiceGroup = button_groups.get(die_type)
		if not button_group:
			button_group = _breath_dice_group.instantiate()
			button_group.die_type = die_type
			button_groups[die_type] = button_group
			_die_types.add(button_group)

func _set_character(new_character: Character) -> void:
	assert(new_character)
	if character != null:
		character.breath_dice_changed.disconnect(_on_breath_dice_changed)
		character.breath_dice_states_changed.disconnect(_on_breath_dice_states_changed)
	character = new_character
	setup_breath_dice(character.breath_dice)
	character.breath_dice_changed.connect(_on_breath_dice_changed)
	character.breath_dice_states_changed.connect(_on_breath_dice_states_changed)

func _on_breath_dice_changed(breath_dice: Array[BreathDie]) -> void:
	setup_breath_dice(breath_dice)

func _on_breath_dice_states_changed() -> void:
	setup_breath_dice(character.breath_dice)
