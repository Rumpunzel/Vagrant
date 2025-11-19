class_name StoryFightDecision
extends StoryDiceDecision

var _adventure_fight_decision: AdventureFightDecision

var _fight_request: FightRequest:
	set(new_fight_request):
		assert((new_fight_request == null) != (_fight_request == null)) # One of the must be null, the other must not
		if _fight_request:
			_fight_request.fight_rolled.disconnect(_on_dice_rolled)
		_fight_request = new_fight_request
		if not _fight_request: return
		_fight_request.fight_rolled.connect(_on_dice_rolled)

var _fight_result: FightResult:
	set(new_fight_result):
		assert(new_fight_result)
		assert(not _fight_result)
		_fight_result = new_fight_result

func _init(adventure_fight_decision: AdventureFightDecision, protagonist_getter: Callable) -> void:
	_adventure_fight_decision = adventure_fight_decision
	_protagonist_getter = protagonist_getter

func get_adventure_decision() -> AdventureFightDecision: return _adventure_fight_decision
func get_transition() -> AdventurePage: return null

func get_icon() -> Texture2D:
	var custom_icon: Texture2D = get_adventure_decision().get_icon()
	if custom_icon: return custom_icon
	return get_attribute().fight_icon

func get_icon_color() -> Color:
	var custom_color: Color = get_adventure_decision().get_color()
	if custom_color != Color.WHITE: return custom_color
	return get_attribute().color

func get_dice_request() -> FightRequest: return _fight_request
func get_dice_result() -> FightResult: return _fight_result

func get_attribute() -> CharacterAttribute:
	return _fight_request.attribute if _fight_request else get_protagonist().get_favored_attribute()

func set_dice_request(dice_request: DiceRequest) -> void:
	super.set_dice_request(dice_request)
	_fight_request = dice_request as FightRequest

func set_dice_result(dice_result: DiceResult) -> void:
	assert(dice_result is FightResult)
	_fight_result = dice_result
