class_name StoryFightDecision
extends StoryDiceDecision

var _adventure_fight_decision: AdventureFightDecision

var fight_request: FightRequest:
	set(new_fight_request):
		assert((new_fight_request == null) != (fight_request == null)) # One of the must be null, the other must not
		if fight_request:
			fight_request.fight_rolled.disconnect(_on_dice_rolled)
		fight_request = new_fight_request
		if not fight_request: return
		fight_request.fight_rolled.connect(_on_dice_rolled)

var fight_result: FightResult:
	set(new_fight_result):
		assert(new_fight_result)
		assert(not fight_result)
		fight_result = new_fight_result

func _init(adventure_fight_decision: AdventureFightDecision, protagonist_getter: Callable) -> void:
	_adventure_fight_decision = adventure_fight_decision
	_protagonist_getter = protagonist_getter

func get_adventure_decision() -> AdventureFightDecision: return _adventure_fight_decision
func get_transition() -> AdventurePage: return null

func get_icon() -> Texture2D:
	var custom_icon: Texture2D = get_adventure_decision().get_icon()
	if custom_icon: return custom_icon
	return get_protagonist().get_highest_attribute().fight_icon

func get_icon_color() -> Color:
	var custom_color: Color = get_adventure_decision().get_color()
	if custom_color != Color.WHITE: return custom_color
	return get_protagonist().get_highest_attribute().color

func get_dice_request() -> FightRequest: return fight_request
func get_dice_result() -> FightResult: return fight_result

func set_dice_request(dice_request: DiceRequest) -> void:
	fight_request = dice_request as FightRequest
	super.set_dice_request(dice_request)

func set_dice_result(dice_result: DiceResult) -> void:
	assert(dice_result is FightResult)
	fight_result = dice_result
