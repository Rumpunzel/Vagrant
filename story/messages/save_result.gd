@tool
class_name SaveResult
extends DiceRequestResult

func get_dice_request() -> SaveRequest: return dice_request
func get_outcome() -> Outcome: return Outcome.SUCCESS if get_highest_result() >= get_dice_request().get_difficulty() else Outcome.FAILURE
func get_margin() -> int: return abs(get_dice_request().get_difficulty() - get_highest_result())

func get_die_color(die: Die) -> Color:
	assert(die is BreathDie)
	var breath_die: BreathDie = die
	match get_outcome():
		Outcome.SUCCESS: if breath_die.result == get_highest_result(): return Main.SUCCESS if breath_die.alive else Main.INFO
		Outcome.FAILURE: return Main.FAILURE
		_: assert(false, "SaveResult.Outcome %s is not supported!" % get_outcome())
	return Color.WHITE
