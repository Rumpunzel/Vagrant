class_name Die

signal rolled(die: Die)
signal reconsidered_for_save(selected_for_save: bool)

enum Status {
	ALIVE,
	EXHAUSTED,
}

var die_type: DieType
var result: int
var status: Status
var selected_for_save := false :
	set(new_selected_for_save):
		selected_for_save = new_selected_for_save
		reconsidered_for_save.emit(selected_for_save)

func _init(new_die_type: DieType, new_result: int = 0, new_status: Status = Status.ALIVE) -> void:
	die_type = new_die_type
	result = new_result
	status = new_status

func roll() -> int:
	result = die_type.roll()
	rolled.emit(self)
	return result

func roll_save(attribute_score: int) -> int:
	result = die_type.roll()
	if result > attribute_score: status = Status.EXHAUSTED
	rolled.emit(self)
	return result

func is_alive() -> bool:
	return status == Status.ALIVE

func get_die_color(save_difficulty: int) -> Color:
	var color: Color = Color.WHITE
	if save_difficulty <= 0: return color
	if result >= save_difficulty:
		color = Color.LIME_GREEN if is_alive() else Color.CORNFLOWER_BLUE
	else:
		color = Color.ORANGE if is_alive() else Color.FIREBRICK
	return color

func _to_string() -> String:
	return "%s → %d" % [die_type, result]
