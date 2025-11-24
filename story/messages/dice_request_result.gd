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
	var dice_pool: Array[Die] = DiceRoller.generate_dice_pool(dice_request.selected_breath_dice)
	for die: Die in dice_pool: die.roll()
	super(dice_pool)

func is_success() -> bool: return get_outcome() == Outcome.SUCCESS

@abstract func get_dice_request() -> DiceRequest
@abstract func get_outcome() -> Outcome
@abstract func get_margin() -> int

func get_breath_dice() -> Array[Die]:
	var breath_dice: Array[Die]
	breath_dice.assign(dice)
	return breath_dice

func get_highest_breath_dice() -> Array[Die]:
	var highest_breath_dice: Array[Die] = []
	highest_breath_dice.assign(get_highest_dice())
	return highest_breath_dice
