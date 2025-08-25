@tool
class_name AttributeScore
extends Resource

@export var rolled_dice: Array[Die]

func _init(new_rolled_dice: Array[Die]) -> void:
	rolled_dice = new_rolled_dice

func get_score() -> int:
	var score: int = 0
	for die: Die in rolled_dice:
		score += die.result
	return score

func get_dice() -> String:
	return " + ".join(rolled_dice.map(func (die: Die) -> String: return "%d" % die.result))
