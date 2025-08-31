class_name Die
extends Resource

signal rolled(result: int)

@export var die_type: DieType
@export var result: int

func _init(new_die_type: DieType = null, new_result: int = 0) -> void:
	die_type = new_die_type
	result = new_result

func roll(play_sound: bool = true) -> int:
	assert(die_type)
	result = die_type.roll(play_sound)
	rolled.emit(result)
	return result

func _to_string() -> String:
	return "%s → %d" % [die_type, result]
