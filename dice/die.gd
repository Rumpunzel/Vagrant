class_name Die
extends Resource

signal rolled(result: int)

@export var die_type: DieType
@export var result: int

func _init(new_die_type: DieType = null, new_result: int = 0) -> void:
	die_type = new_die_type
	result = new_result

static func compare_ascending(first_die: Die, second_die: Die) -> bool:
	return first_die.die_type.faces < second_die.die_type.faces

static func compare_descending(first_die: Die, second_die: Die) -> bool:
	return first_die.die_type.faces > second_die.die_type.faces

func roll(play_sound: bool = true) -> int:
	assert(die_type)
	result = die_type.roll(play_sound)
	rolled.emit(result)
	return result

func is_auto_selected(attribute_score: AttributeScore) -> bool:
	return die_type.is_auto_selected(attribute_score)

func _to_string() -> String:
	return "%s → %d" % [die_type, result]
