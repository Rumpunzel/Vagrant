class_name Die

signal rolled(die: Die)

enum Status {
	ALIVE,
	EXHAUSTED,
}

var die_type: DieType
var result: int
var status: Status

func _init(new_die_type: DieType, new_result: int = 0, new_status: Status = Status.ALIVE) -> void:
	die_type = new_die_type
	result = new_result
	status = new_status

func roll() -> int:
	_roll()
	rolled.emit(self)
	return result

func roll_save(attribute_score: int) -> int:
	_roll()
	if result > attribute_score: status = Status.EXHAUSTED
	rolled.emit(self)
	return result

func _roll() -> void:
	status = Status.ALIVE
	result = randi_range(1, die_type.faces)

func _to_string() -> String:
	return "%s → %d" % [die_type, result]
