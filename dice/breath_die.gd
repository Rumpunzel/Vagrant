class_name BreathDie
extends Die

signal rolled_save(result: int, state: State)
signal state_changed(state: State)

enum State {
	LOST = -1,
	EXHAUSTED,
	ALIVE,
}

@export var state: State = State.ALIVE:
	set(new_state):
		if new_state == state: return
		state = new_state
		state_changed.emit(state)

func roll_save(attribute_score: int, play_sound: bool = true) -> int:
	result = die_type.roll(play_sound)
	if result > attribute_score: state = State.EXHAUSTED
	rolled_save.emit(result, state)
	return result

func is_alive() -> bool:
	return state >= State.ALIVE

func is_exhausted() -> bool:
	return state == State.EXHAUSTED

func is_spendable() -> bool:
	return state >= State.EXHAUSTED

func is_lost() -> bool:
	return state <= State.LOST

func is_auto_selected(attribute_score: AttributeScore) -> bool:
	return attribute_score.get_score() >= die_type.faces
