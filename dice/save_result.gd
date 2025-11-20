@tool
class_name SaveResult
extends DiceResult

enum Outcome {
	FAILURE = -1,
	SUCCESS = 1,
}

var save_request: SaveRequest

func _init(for_save_request: SaveRequest) -> void:
	save_request = for_save_request
	super(save_request.get_selected_dice())

func is_success() -> bool: return get_save_outcome() == Outcome.SUCCESS

func get_breath_dice() -> Array[BreathDie]:
	var breath_dice: Array[BreathDie]
	breath_dice.assign(dice)
	return breath_dice

func get_save_outcome() -> Outcome:
	return Outcome.SUCCESS if get_highest_result() >= save_request.get_difficulty() else Outcome.FAILURE

func get_highest_breath_dice() -> Array[BreathDie]:
	var highest_breath_dice: Array[BreathDie] = []
	highest_breath_dice.assign(get_highest_dice())
	return highest_breath_dice

func get_die_color(die: BreathDie) -> Color:
	match get_save_outcome():
		Outcome.SUCCESS: return Main.SUCCESS if die.alive else Main.INFO
		Outcome.FAILURE: return Main.FAILURE
		_: assert(false, "SaveResult.Outcome %s is not supported!" % get_save_outcome())
	return Color.BLACK
