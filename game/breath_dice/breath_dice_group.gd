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

var _highlight_tween: Tween

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

func highlight(frequency: float = 1.0) -> void:
	assert(frequency > 0.0)
	if _highlight_tween: _highlight_tween.kill()
	_highlight_tween = create_tween().set_loops()
	_highlight_tween.tween_property(self, "modulate:a", 0.5, 1.0 / frequency).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_IN)
	_highlight_tween.tween_property(self, "modulate:a", modulate.a, 1.0 / frequency).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)

func stop_highlighting() -> void:
	if _highlight_tween: _highlight_tween.kill()
	modulate.a = 1.0
