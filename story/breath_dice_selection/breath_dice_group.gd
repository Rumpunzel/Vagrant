@tool
class_name BreathDiceGroup
extends FlexContainer

@export var _breath_die_display: PackedScene

func add_breath_die(breath_die: BreathDie) -> void:
	var breath_die_display: BreathDieDisplay = _breath_die_display.instantiate()
	breath_die_display.breath_die = breath_die
	var stack_color: Color = Color.WHITE * pow(0.5, get_elements().size())
	stack_color.a = 1.0
	breath_die_display.self_modulate = stack_color
	add(breath_die_display)
