@tool
class_name BreathDiceGroup
extends FlexContainer

@export var _breath_die_display: PackedScene

func add_breath_die(breath_die: BreathDie) -> void:
	var breath_die_display: BreathDieDisplay = _breath_die_display.instantiate()
	breath_die_display.breath_die = breath_die
	add(breath_die_display)
