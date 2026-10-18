extends GdUnitTestSuite

## Saves: SaveRequest -> SaveResult, and how StorySaveDecision picks its transition and consequences.

const DORIAN: String = "uid://73nsysikxf7j"  # dorian.tres
const CHARACTER: String = "uid://bl0pdxri24fnh"  # character.tscn

var _character: Character
var _decision: AdventureSaveDecision
var _success_page: AdventurePage
var _failure_page: AdventurePage
var _consequence: AdventureConsequence
var _failure_consequence: AdventureConsequence

func before_test() -> void:
	_character = auto_free(load(CHARACTER).instantiate())
	add_child(_character)
	_character.character_profile = (load(DORIAN) as CharacterProfile).duplicate(true)
	_success_page = AdventurePage.new()
	_failure_page = AdventurePage.new()
	_consequence = AdventureInjuryConsequence.new()
	_failure_consequence = AdventureInjuryConsequence.new()
	_decision = AdventureSaveDecision.new()
	_decision.description = "Jump"
	_decision.attribute = Rules.AGILITY
	_decision.difficulty = 5
	_decision.transition = _success_page
	_decision.failure_transition = _failure_page
	_decision.consequences = [_consequence] as Array[AdventureConsequence]
	_decision.failure_consequences = [_failure_consequence] as Array[AdventureConsequence]

func test_request_uses_decision_attribute_and_auto_selects() -> void:
	var request: SaveRequest = _decision.to_dice_request(_character)
	assert_object(request.attribute).is_same(Rules.AGILITY)
	assert_int(request.get_difficulty()).is_equal(5)
	assert_dict(request.selected_breath_dice).is_equal(_character.get_auto_selected_breath_dice(Rules.AGILITY))

func test_select_and_deselect_breath_dice() -> void:
	var request: SaveRequest = _decision.to_dice_request(_character)
	request.selected_breath_dice = {} as Dictionary[DieType, int]
	request.select_breath_die(Rules.d12)
	request.select_breath_die(Rules.d12)
	assert_int(request.selected_breath_dice[Rules.d12]).is_equal(2)
	request.deselect_breath_die(Rules.d12)
	assert_int(request.selected_breath_dice[Rules.d12]).is_equal(1)

func test_roll_uses_selected_dice() -> void:
	var request: SaveRequest = _decision.to_dice_request(_character)
	request.selected_breath_dice = {Rules.d4: 1, Rules.d8: 1} as Dictionary[DieType, int]
	var result: SaveResult = request.roll()
	assert_int(result.dice.size()).is_equal(2)
	for die: Die in result.dice: assert_int(die.result).is_between(1, die.die_type.faces)

func test_outcome_and_margin() -> void:
	var result: SaveResult = _roll_with([Die.new(Rules.d8, 7), Die.new(Rules.d4, 2)])
	assert_int(result.get_outcome()).is_equal(DiceRequestResult.Outcome.SUCCESS)
	assert_int(result.get_margin()).is_equal(2)
	result = _roll_with([Die.new(Rules.d4, 3)])
	assert_int(result.get_outcome()).is_equal(DiceRequestResult.Outcome.FAILURE)
	assert_int(result.get_margin()).is_equal(2)
	# Meeting the difficulty is enough
	assert_bool(_roll_with([Die.new(Rules.d6, 5)]).is_success()).is_true()

func test_dice_above_the_score_are_lost() -> void:
	var score: int = _character.get_attribute_score(Rules.AGILITY).get_score()
	var above: Die = Die.new(Rules.d12, score + 1)
	var at: Die = Die.new(Rules.d12, score)
	var result: SaveResult = _roll_with([above, at])
	var expected: Array[Die] = [above]
	for origin: Origin in _character.character_profile.origins: expected = origin.get_lost_breath_dice(expected)
	assert_array(result.get_lost_breath_dice()).is_equal(expected)

func test_story_decision_follows_outcome() -> void:
	var choice: StorySaveDecision = StoryChoice.from_adventure_decision(_decision, _character)
	assert_bool(choice.is_dice_choice()).is_true()
	assert_bool(choice.is_chosen()).is_false()
	var request: SaveRequest = choice.get_dice_request()
	request.selected_breath_dice = {Rules.d4: 1} as Dictionary[DieType, int]
	var result: SaveResult = request.roll()
	assert_bool(choice.is_chosen()).is_true()
	result.dice = [Die.new(Rules.d8, 8)] as Array[Die]
	assert_object(choice.get_transition()).is_same(_success_page)
	assert_object(choice.get_consequences()[0]._adventure_consequence).is_same(_consequence)
	result.dice = [Die.new(Rules.d4, 1)] as Array[Die]
	assert_object(choice.get_transition()).is_same(_failure_page)
	assert_object(choice.get_consequences()[0]._adventure_consequence).is_same(_failure_consequence)

func test_icon_and_color_default_to_attribute() -> void:
	assert_object(_decision.get_icon()).is_same(Rules.AGILITY.icon)
	assert_object(_decision.get_color()).is_equal(Rules.AGILITY.color)

func _roll_with(dice: Array) -> SaveResult:
	var request: SaveRequest = _decision.to_dice_request(_character)
	var result: SaveResult = request.roll()
	result.dice.assign(dice)
	return result
