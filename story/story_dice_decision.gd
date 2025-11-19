@abstract
class_name StoryDiceDecision
extends StoryChoice

signal dice_requested(dice_request: DiceRequest)

var _protagonist_getter: Callable

func chose() -> void:
	assert(not is_chosen())
	if get_dice_request(): return
	set_dice_request(get_adventure_decision().to_dice_request(get_protagonist()))

func discard() -> void:
	assert(not is_chosen())
	if not get_dice_request(): return
	set_dice_request(null)

func is_chosen() -> bool: return get_dice_result() != null
func is_dice_choice() -> bool: return true

func get_protagonist() -> Character: return _protagonist_getter.call()

@abstract func get_adventure_decision() -> AdventureDiceDecision
@abstract func get_dice_request() -> DiceRequest
@abstract func get_dice_result() -> DiceResult

func set_dice_request(dice_request: DiceRequest) -> void:
	if get_dice_request():
		get_dice_request().attribute_changed.disconnect(_on_dice_request_attribute_changed)
	if dice_request:
		dice_request.attribute_changed.connect(_on_dice_request_attribute_changed)
	dice_requested.emit(dice_request)
	icon_changed.emit()

@abstract func set_dice_result(dice_result: DiceResult) -> void

func _on_dice_request_attribute_changed(_attribute: CharacterAttribute) -> void:
	icon_changed.emit()

func _on_dice_rolled(dice_result: DiceResult) -> void:
	set_dice_result(dice_result)
	_chose()
