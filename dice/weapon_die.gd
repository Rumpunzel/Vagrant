class_name WeaponDie
extends Die

signal rolled_damage(result: int, state: State)
signal state_changed(state: State)

enum State {
	LOST = -8,
	EXHAUSTED = -1,
	ALIVE,
}

@export var state: State = State.ALIVE:
	set(new_state):
		if new_state == state: return
		state = new_state
		state_changed.emit(state)

func roll_damage(attribute_score: int, play_sound: bool = true) -> int:
	result = die_type.roll(play_sound)
	if result > attribute_score: state = State.EXHAUSTED
	rolled_damage.emit(result, state)
	return result

func deselect() -> void:
	if not is_alive(): return
	state = State.ALIVE

func is_alive() -> bool:
	return state >= State.ALIVE
