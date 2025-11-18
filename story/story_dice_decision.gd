@abstract
class_name StoryDiceDecision
extends StoryChoice

signal dice_requested(dice_request: DiceRequest)

var _protagonist: Character

func chose() -> void:
	assert(not is_chosen())
	if get_dice_request(): return
	set_dice_request(get_adventure_decision().to_dice_request(_protagonist))

func discard() -> void:
	assert(not is_chosen())
	if not get_dice_request(): return
	set_dice_request(null)

func is_chosen() -> bool: return get_dice_result() != null
func is_dice_choice() -> bool: return true

@abstract func get_adventure_decision() -> AdventureDiceDecision
@abstract func get_dice_request() -> DiceRequest
@abstract func get_dice_result() -> DiceResult

func set_dice_request(dice_request: DiceRequest) -> void: dice_requested.emit(dice_request)
@abstract func set_dice_result(dice_result: DiceResult) -> void

func _on_dice_rolled(dice_result: DiceResult) -> void:
	set_dice_result(dice_result)
	_chose()
