@tool
class_name BreathDieDisplay
extends TextureRect

@export var breath_die: BreathDie :
	set(new_breath_die):
		assert(new_breath_die)
		breath_die = new_breath_die
		_die_type = breath_die.die_type
		_update()
		breath_die.state_changed.connect(_on_die_state_changed)

@export var _die_type: DieType :
	set(new_die_type):
		_die_type = new_die_type
		if not _die_type: return
		texture = _die_type.icon
@export var _alive_modulate: Color = Color(1.0, 1.0, 1.0, 0.5)
@export var _exhausted_modulate: Color = Color(1.0, 1.0, 1.0, 0.1)

func _update() -> void:
	modulate = _alive_modulate if breath_die.is_alive() else _exhausted_modulate

func _on_die_state_changed(_die_state: BreathDie.State) -> void:
	_update()
