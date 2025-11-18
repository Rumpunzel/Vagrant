class_name StoryBookFightDecision
extends StoryBookDiceDecision

var _story_fight_decision: StoryFightDecision

var fight_request: FightRequest :
	set(new_fight_request):
		assert((new_fight_request == null) != (fight_request == null)) # One of the must be null, the other must not
		if fight_request:
			fight_request.fight_rolled.disconnect(_on_dice_rolled)
		fight_request = new_fight_request
		fight_request.fight_rolled.connect(_on_dice_rolled)

var fight_result: FightResult :
	set(new_fight_result):
		assert(new_fight_result)
		assert(not fight_result)
		fight_result = new_fight_result

func _init(story_fight_decision: StoryFightDecision, protagonist: Character) -> void:
	_story_fight_decision = story_fight_decision
	_protagonist = protagonist

func get_story_decision() -> StoryFightDecision: return _story_fight_decision
func get_transition() -> StoryPage: return null

func get_dice_request() -> FightRequest: return fight_request
func get_dice_result() -> FightResult: return fight_result

func set_dice_request(dice_request: DiceRequest) -> void:
	assert(dice_request is FightRequest)
	fight_request = dice_request as FightRequest
	super.set_dice_request(dice_request)

func set_dice_result(dice_result: DiceResult) -> void:
	assert(dice_result is FightResult)
	fight_result = dice_result
