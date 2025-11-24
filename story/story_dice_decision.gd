@abstract
class_name StoryDiceDecision
extends StoryChoice

var dice_request: DiceRequest:
	set(new_dice_request):
		assert((new_dice_request == null) != (dice_request == null)) # One of the must be null, the other must not
		if dice_request:
			dice_request.attribute_changed.disconnect(_on_dice_request_attribute_changed)
			dice_request.rolled.disconnect(_on_dice_rolled)
		dice_request = new_dice_request
		icon_changed.emit()
		if not dice_request: return
		dice_request.attribute_changed.connect(_on_dice_request_attribute_changed)
		dice_request.rolled.connect(_on_dice_rolled)

var dice_result: DiceRequestResult:
	set(new_dice_result):
		assert(new_dice_result)
		assert(not dice_result)
		dice_result = new_dice_result

func chose() -> void:
	assert(not is_chosen())
	assert(dice_request)
	dice_requested.emit(dice_request)

func roll() -> void:
	assert(not is_chosen())
	assert(dice_request)
	roll_requested.emit(dice_request)

func is_chosen() -> bool: return get_dice_result() != null
func is_dice_choice() -> bool: return true

@abstract func get_adventure_decision() -> AdventureDiceDecision

func _setup(protagonist: Character) -> void:
	dice_request = get_adventure_decision().to_dice_request(protagonist)

func _on_dice_request_attribute_changed(_attribute: CharacterAttribute) -> void: icon_changed.emit()

func _on_dice_rolled(rolled_dice_result: DiceResult) -> void:
	dice_result = rolled_dice_result
	#_chose()
