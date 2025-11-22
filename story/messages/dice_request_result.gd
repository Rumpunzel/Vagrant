@tool
@abstract
class_name DiceRequestResult
extends DiceResult

enum Outcome {
	FAILURE = -1,
	DRAW,
	SUCCESS,
}

var dice_request: DiceRequest

func _init(for_dice_request: DiceRequest) -> void:
	dice_request = for_dice_request
	super(dice_request.get_selected_dice())

func is_success() -> bool: return get_outcome() == Outcome.SUCCESS

@abstract func get_dice_request() -> DiceRequest
@abstract func get_outcome() -> Outcome
@abstract func get_margin() -> int

func get_breath_dice() -> Array[BreathDie]:
	var breath_dice: Array[BreathDie]
	breath_dice.assign(dice)
	return breath_dice

func get_highest_breath_dice() -> Array[BreathDie]:
	var highest_breath_dice: Array[BreathDie] = []
	highest_breath_dice.assign(get_highest_dice())
	return highest_breath_dice
