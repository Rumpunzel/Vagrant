class_name StoryBookSaveDecision
extends StoryBookDiceDecision

var _story_save_decision: StorySaveDecision

var save_request: SaveRequest :
	set(new_save_request):
		assert((new_save_request == null) != (save_request == null)) # One of the must be null, the other must not
		if save_request:
			save_request.save_rolled.disconnect(_on_dice_rolled)
		save_request = new_save_request
		save_request.save_rolled.connect(_on_dice_rolled)

var save_result: SaveResult :
	set(new_save_result):
		assert(new_save_result)
		assert(not save_result)
		save_result = new_save_result

func _init(story_save_decision: StorySaveDecision, protagonist: Character) -> void:
	_story_save_decision = story_save_decision
	_protagonist = protagonist

func get_story_decision() -> StorySaveDecision: return _story_save_decision
func get_transition() -> StoryPage:
	if save_result.get_save_outcome() != SaveResult.Outcome.FAILURE:
		return _story_save_decision.transition.get_story_page()
	else:
		return _story_save_decision.failure_transition.get_story_page()

func get_dice_request() -> SaveRequest: return save_request
func get_dice_result() -> SaveResult: return save_result

func set_dice_request(dice_request: DiceRequest) -> void:
	assert(dice_request is SaveRequest)
	save_request = dice_request
	super.set_dice_request(dice_request)

func set_dice_result(dice_result: DiceResult) -> void:
	assert(dice_result is SaveResult)
	save_result = dice_result
