@tool
class_name SaveResult
extends DiceResult

enum Outcome {
	SUCCESS,
	FAILURE,
}

var save_request: SaveRequest

func _init(for_save_request: SaveRequest) -> void:
	save_request = for_save_request
	super(save_request.selected_breath_die_as_dice())

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
		Outcome.SUCCESS: return Color.LIME_GREEN if die.is_alive() else Color.CORNFLOWER_BLUE
		Outcome.FAILURE: return Color.FIREBRICK
		_: assert(false, "SaveResult.Outcome %s is not supported!" % get_save_outcome())
	return Color.BLACK
