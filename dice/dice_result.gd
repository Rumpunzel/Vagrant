@tool
class_name DiceResult
extends Resource

@export var dice: Array[Die]

func _init(rolled_dice: Array[Die]) -> void:
	dice = rolled_dice

func get_sum() -> int:
	return dice.reduce(func(sum: int, die: Die) -> int: return sum + die.result, 0)

func get_highest_result() -> int:
	return dice.reduce(func(result: int, die: Die) -> int: return die.result if die.result > result else result)

func get_highest_dice() -> Array[Die]:
	return dice.filter(func(die: Die) -> bool: return die.result == get_highest_result())

func format_sum() -> String:
	return "%s = %d" % [self, get_sum()]

func format_highest_result() -> String:
	return "%s = %d" % [self, get_highest_result()]

func _to_string() -> String:
	return "[ %s ]" % " + ".join(dice.map(func(die: Die) -> String: return "%d" % die.result))
