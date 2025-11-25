@tool
class_name SaveResult
extends DiceRequestResult

func get_dice_request() -> SaveRequest: return dice_request
func get_outcome() -> Outcome: return Outcome.SUCCESS if get_highest_result() >= get_dice_request().get_difficulty() else Outcome.FAILURE
func get_margin() -> int: return abs(get_dice_request().get_difficulty() - get_highest_result())

func get_die_color(die: Die) -> Color:
	match get_outcome():
		Outcome.SUCCESS:
			if die.result == get_highest_result():
				var attribute_score: AttributeScore = get_dice_request().character.get_attribute_score(get_dice_request().attribute)
				return Main.INFO if die.result > attribute_score.get_score() else Main.SUCCESS
		Outcome.FAILURE: return Main.FAILURE
		_: assert(false, "SaveResult.Outcome %s is not supported!" % get_outcome())
	return Color.WHITE
