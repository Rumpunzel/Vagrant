@tool
class_name FightResult
extends DiceRequestResult

func get_dice_request() -> FightRequest: return dice_request
func get_outcome() -> Outcome: return Outcome.SUCCESS# if get_highest_result() >= get_dice_request().get_difficulty() else Outcome.FAILURE
func get_margin() -> int: return 0# abs(get_dice_request().get_difficulty() - get_highest_result())

func get_die_color(_die: Die) -> Color:
	#match get_save_outcome():
		#Outcome.SUCCESS: return Main.SUCCESS if die.is_alive() else Main.INFO
		#Outcome.FAILURE: return Main.FAILURE
		#_: assert(false, "SaveResult.Outcome %s is not supported!" % get_save_outcome())
	return Color.WHITE
