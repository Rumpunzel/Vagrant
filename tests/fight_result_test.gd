extends GdUnitTestSuite

## FightRequest -> FightResult wiring with real resources; dice are random, so invariants are checked over many rolls.

const ROLLS: int = 50

var _character: Character
var _monster: Monster

func before_test() -> void:
	var profile: CharacterProfile = (load("res://characters/dorian.tres") as CharacterProfile).duplicate(true)
	profile.weapon_dice = [Rules.d10] as Array[DieType]
	_character = auto_free(load("res://characters/character.tscn").instantiate())
	add_child(_character)
	_character.character_profile = profile
	_monster = auto_free(load("res://characters/monsters/monster.tscn").instantiate())
	var lurker: MonsterProfile = (load("res://characters/monsters/lurker.tres") as MonsterProfile).duplicate(true)
	lurker.weapon_dice = [Rules.d8] as Array[DieType]
	add_child(_monster)
	_monster.monster_profile = lurker

func test_builds_both_sides() -> void:
	for _roll: int in ROLLS:
		var request: FightRequest = _create_request()
		var result: FightResult = request.roll()
		var player: FightSide = result.get_player_side()
		var opponent: FightSide = result.get_opponent_side()
		assert_array(player.breath_dice).is_equal(result.dice)
		assert_int(player.breath_dice.size()).is_equal(_selected_count(request))
		assert_int(player.weapon_dice.size()).is_equal(1)
		assert_int(opponent.breath_dice.size()).is_equal(3)
		assert_int(opponent.weapon_dice.size()).is_equal(1)
		assert_object(opponent.stance).is_same(_monster.get_nature())
		for attribute: CharacterAttribute in Rules.ATTRIBUTES:
			assert_int(player.scores[attribute]).is_equal(_character.get_attribute_score(attribute).get_score())
			assert_int(opponent.scores[attribute]).is_equal(_monster.get_score(attribute))

func test_outcome_and_margin_follow_threat() -> void:
	for _roll: int in ROLLS:
		var result: FightResult = _create_request().roll()
		var difference: int = result.get_player_side().threat - result.get_opponent_side().threat
		assert_int(result.get_margin()).is_equal(absi(difference))
		var expected: DiceRequestResult.Outcome = DiceRequestResult.Outcome.DRAW
		if difference > 0: expected = DiceRequestResult.Outcome.SUCCESS
		elif difference < 0: expected = DiceRequestResult.Outcome.FAILURE
		assert_int(result.get_outcome()).is_equal(expected)

func test_lost_breath_dice_come_from_exchange() -> void:
	for _roll: int in ROLLS:
		var result: FightResult = _create_request().roll()
		var lost: Array[Die] = result.get_lost_breath_dice()
		for die: Die in lost: assert_bool(result.get_player_side().lost_breath_dice.has(die)).is_true()

func test_fleeing_rolls_blood() -> void:
	var request: FightRequest = _create_request()
	request.fleeing = true
	var result: FightResult = request.roll()
	assert_object(result.get_player_side().stance).is_same(Rules.AGILITY)

func test_character_loses_breath_dice() -> void:
	var request: FightRequest = _create_request()
	var before: int = _total(_character.breath_dice)
	var result: FightResult = request.roll()
	_character.parse_dice_result(result)
	assert_int(_total(_character.breath_dice)).is_equal(before - result.get_lost_breath_dice().size())

func _create_request() -> FightRequest:
	var request: FightRequest = FightRequest.new(_character, AdventureFightDecision.new())
	request.opponent = _monster
	request.attribute = Rules.STRENGTH
	# Roll every breath die so losses are likely
	request.selected_breath_dice = _character.breath_dice.duplicate()
	return request

func _selected_count(request: FightRequest) -> int:
	return _total(request.selected_breath_dice)

func _total(dice: Dictionary[DieType, int]) -> int:
	var total: int = 0
	for amount: int in dice.values(): total += amount
	return total
