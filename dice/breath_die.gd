class_name BreathDie
extends Die

signal rolled_save(result: int, alive: bool)
signal state_changed(alive: bool)

@export var alive: bool = true:
	set(new_state):
		if new_state == alive: return
		alive = new_state
		state_changed.emit(alive)

func roll_save(attribute_score: int, play_sound: bool = true) -> int:
	result = die_type.roll(play_sound)
	alive = result <= attribute_score
	rolled_save.emit(result, alive)
	return result

func is_auto_selected(attribute_score: AttributeScore) -> bool:
	return die_type.faces <= attribute_score.get_score()
