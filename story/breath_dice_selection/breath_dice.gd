@tool
class_name BreathDice
extends FlexCurveContainer

@export_group("Configuration")
@export var _breath_dice_group: PackedScene

var _groups: Dictionary[DieType, BreathDiceGroup] = {}

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
	_groups.clear()
	clear()
	for breath_die: BreathDie in breath_dice:
		var group: BreathDiceGroup = _groups.get(breath_die.die_type)
		if not group:
			group = _breath_dice_group.instantiate()
			_groups[breath_die.die_type] = group
			add(group)
		group.add_breath_die(breath_die)
