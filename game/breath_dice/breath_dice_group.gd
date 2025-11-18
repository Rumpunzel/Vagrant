@tool
class_name BreathDiceGroup
extends FlexContainer

signal die_type_changed(die_type: DieType)
signal breath_die_button_added(breath_die_button: BreathDieButton)

@export var die_type: DieType :
	set(new_die_type):
		die_type = new_die_type
		die_type_changed.emit(die_type)

@export_group("Configuration")
@export var _breath_die_button: PackedScene

func setup_breath_dice(breath_dice: Array[BreathDie]) -> void:
	clear()
	if breath_dice.is_empty():
		var dummy_button: BreathDieButton = _breath_die_button.instantiate()
		dummy_button.die_type = die_type
		dummy_button.disabled = true
		dummy_button.flat = true
		dummy_button.tooltip_text = "All %s are lost." % die_type
		dummy_button.mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
		add(dummy_button)
	for breath_die: BreathDie in breath_dice:
		assert(breath_die.die_type == die_type)
		add_breath_die(breath_die)

func add_breath_die(breath_die: BreathDie) -> void:
	var breath_die_button: BreathDieButton = _breath_die_button.instantiate()
	breath_die_button.breath_die = breath_die
	add(breath_die_button)
	breath_die_button_added.emit(breath_die_button)
