@tool
class_name RolledAttributeScore
extends DiceResult

func get_score() -> int:
	return get_sum()

func get_type() -> AttributeScore.Type:
	if dice.is_empty(): return AttributeScore.Type.NORMAL
	var first_die: Die = dice.front()
	var last_result: int = first_die.result
	for die: Die in dice:
		if not die.result == last_result: return AttributeScore.Type.NORMAL
		last_result = die.result
	return AttributeScore.Type.DOUBLE
