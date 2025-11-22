@tool
class_name FightResult
extends DiceResult

enum Outcome {
	LOST = -1,
	DRAW,
	WON,
}

var fight_request: FightRequest

func _init(for_fight_request: FightRequest) -> void:
	fight_request = for_fight_request
	super(fight_request.get_selected_dice())

func get_breath_dice() -> Array[BreathDie]:
	var breath_dice: Array[BreathDie]
	breath_dice.assign(dice)
	return breath_dice

#func get_fight_outcome() -> Outcome:
	#return Outcome.SUCCESS if get_highest_result() >= fight_request.get_difficulty() else Outcome.FAILURE

func get_die_color(_die: Die) -> Color:
	#match get_save_outcome():
		#Outcome.SUCCESS: return Main.SUCCESS if die.is_alive() else Main.INFO
		#Outcome.FAILURE: return Main.FAILURE
		#_: assert(false, "SaveResult.Outcome %s is not supported!" % get_save_outcome())
	return Color.WHITE
