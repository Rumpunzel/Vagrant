class_name Die
extends Resource

signal rolled(result: int)

@export var die_type: DieType
@export var result: int

func roll(play_sound: bool = true) -> int:
	result = die_type.roll(play_sound)
	rolled.emit(result)
	return result

func _to_string() -> String:
	return "%s → %d" % [die_type, result]
