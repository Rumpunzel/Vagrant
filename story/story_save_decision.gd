class_name StorySaveDecision
extends StoryDiceDecision

var _adventure_save_decision: AdventureSaveDecision

var save_request: SaveRequest:
	set(new_save_request):
		assert((new_save_request == null) != (save_request == null)) # One of the must be null, the other must not
		if save_request:
			save_request.save_rolled.disconnect(_on_dice_rolled)
		save_request = new_save_request
		if not save_request: return
		save_request.save_rolled.connect(_on_dice_rolled)

var save_result: SaveResult:
	set(new_save_result):
		assert(new_save_result)
		assert(not save_result)
		save_result = new_save_result

func _init(adventure_save_decision: AdventureSaveDecision, protagonist_getter: Callable) -> void:
	_adventure_save_decision = adventure_save_decision
	_protagonist_getter = protagonist_getter

func get_adventure_decision() -> AdventureSaveDecision: return _adventure_save_decision
func get_transition() -> AdventurePage:
	if save_result.get_save_outcome() != SaveResult.Outcome.FAILURE:
		return _adventure_save_decision.transition.get_adventure_page()
	else:
		return _adventure_save_decision.failure_transition.get_adventure_page()

func get_dice_request() -> SaveRequest: return save_request
func get_dice_result() -> SaveResult: return save_result

func set_dice_request(dice_request: DiceRequest) -> void:
	save_request = dice_request
	super.set_dice_request(dice_request)

func set_dice_result(dice_result: DiceResult) -> void:
	assert(dice_result is SaveResult)
	save_result = dice_result
