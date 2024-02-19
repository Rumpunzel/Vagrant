class_name Die

signal rolled(die: Die)
signal state_changed(state: State)

enum State {
	EXHAUSTED = -1,
	ALIVE,
	CONSIDERED,
	SELECTED,
}

var die_type: DieType
var result: int

var _state: State :
	set(new_state):
		if new_state == _state: return
		_state = new_state
		state_changed.emit(_state)

func _init(new_die_type: DieType, new_result: int = 0, new_state: State = State.ALIVE) -> void:
	die_type = new_die_type
	result = new_result
	_state = new_state

func roll(play_sound := true) -> int:
	result = die_type.roll(play_sound)
	rolled.emit(self)
	return result

func roll_save(attribute_score: int, play_sound := true) -> int:
	result = die_type.roll(play_sound)
	if result > attribute_score: _state = State.EXHAUSTED
	rolled.emit(self)
	return result

func update_state(new_state: State = State.ALIVE) -> void:
	_state = new_state

func auto_update_state(attribute_score: int) -> void:
	_state = State.SELECTED if attribute_score >= die_type.faces else State.CONSIDERED

func is_alive() -> bool:
	return _state >= State.ALIVE

func is_considered() -> bool:
	return _state >= State.CONSIDERED

func is_selected() -> bool:
	return _state == State.SELECTED

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
