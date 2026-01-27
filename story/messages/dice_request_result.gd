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

func get_lost_breath_dice() -> Array[Die]:
	var lost_breath_dice: Array[Die] = []
	lost_breath_dice.assign(dice.filter(func(breath_die: Die) -> bool: return breath_die.result > dice_request.get_attribute_score().get_score()))
	for origin: Origin in dice_request.character.character_profile.origins:
		lost_breath_dice = origin.get_lost_breath_dice(lost_breath_dice)
	return lost_breath_dice

func get_highest_breath_dice() -> Array[Die]:
	var highest_breath_dice: Array[Die] = []
	highest_breath_dice.assign(get_highest_dice())
	return highest_breath_dice
