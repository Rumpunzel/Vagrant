@tool
class_name AttributeScore
extends Resource

enum Type {
	NORMAL,
	DOUBLE,
}

@export var rolled_dice: Array[Die]

static func create(new_rolled_dice: Array[Die]) -> AttributeScore:
	var new_attribute_score: AttributeScore = AttributeScore.new()
	new_attribute_score.rolled_dice = new_rolled_dice
	return new_attribute_score

func get_score() -> int:
	var score: int = 0
	for die: Die in rolled_dice:
		score += die.result
	return score

func get_dice() -> String:
	return " + ".join(rolled_dice.map(func (die: Die) -> String: return "%d" % die.result))

func get_type() -> Type:
	if rolled_dice.is_empty(): return Type.NORMAL
	var first_die: Die = rolled_dice.front()
	var last_result: int = first_die.result
	for die: Die in rolled_dice:
		if not die.result == last_result: return Type.NORMAL
		last_result = die.result
	return Type.DOUBLE
