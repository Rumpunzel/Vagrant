class_name Die
extends Resource

signal rolled(die: Die)
signal state_changed(state: State)

enum State {
	LOST = -8,
	EXHAUSTED = -1,
	ALIVE,
	# If the die could be put into a dice pool
	ARMED = 8,
	SELECTED = 16,
}

@export var die_type: DieType
@export var result: int

@export var state: State = State.ALIVE:
	set(new_state):
		if new_state == state: return
		state = new_state
		state_changed.emit(state)

func roll(play_sound: bool = true) -> int:
	result = die_type.roll(play_sound)
	rolled.emit(self)
	return result

func roll_save(attribute_score: int, play_sound: bool = true) -> int:
	result = die_type.roll(play_sound)
	if result > attribute_score: state = State.EXHAUSTED
	rolled.emit(self)
	return result

func update_state(attribute_score: AttributeScore) -> void:
	if not is_alive(): return
	state = State.SELECTED if attribute_score.get_score() >= die_type.faces else State.ARMED

func deselect() -> void:
	if not is_alive(): return
	state = State.ALIVE

func is_alive() -> bool:
	return state >= State.ALIVE

func is_armed() -> bool:
	return state >= State.ARMED

func is_selected() -> bool:
	return state == State.SELECTED

func _to_string() -> String:
	return "%s → %d" % [die_type, result]
