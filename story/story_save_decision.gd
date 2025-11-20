class_name StorySaveDecision
extends StoryDiceDecision

var _save_request: SaveRequest:
	set(new_save_request):
		assert((new_save_request == null) != (_save_request == null)) # One of the must be null, the other must not
		if _save_request:
			_save_request.rolled.disconnect(_on_dice_rolled)
		_save_request = new_save_request
		if not _save_request: return
		_save_request.rolled.connect(_on_dice_rolled)

var _save_result: SaveResult:
	set(new_save_result):
		assert(new_save_result)
		assert(not _save_result)
		_save_result = new_save_result

func resolve_consequences() -> void:
	if _save_result.is_success():
		for consequence: StoryConsequence in get_consequences(): consequence.resolve(null, 0)
	else:
		for consequence: StoryConsequence in get_failure_consequences(): consequence.resolve(get_protagonist(), _save_result.get_margin())

func get_adventure_decision() -> AdventureSaveDecision: return _adventure_decision

func get_transition() -> AdventurePage:
	if _save_result.is_success():
		return get_adventure_decision().transition.get_adventure_page()
	else:
		return get_adventure_decision().failure_transition.get_adventure_page()

func get_failure_consequences() -> Array[StoryConsequence]:
	var story_consequences: Array[StoryConsequence] = []
	story_consequences.assign(get_adventure_decision().failure_consequences.map(StoryConsequence.new))
	return story_consequences

func get_dice_request() -> SaveRequest: return _save_request
func get_dice_result() -> SaveResult: return _save_result

func set_dice_request(dice_request: DiceRequest) -> void:
	super.set_dice_request(dice_request)
	_save_request = dice_request

func set_dice_result(dice_result: DiceResult) -> void:
	assert(dice_result is SaveResult)
	_save_result = dice_result
