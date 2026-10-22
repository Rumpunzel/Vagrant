extends GdUnitTestSuite

## Shields: a raised shield takes its result off the foe's blow, after both stances and before the Gambeson.

const GUTS: CharacterAttribute = Rules.STRENGTH
const BLOOD: CharacterAttribute = Rules.AGILITY

func test_raised_shield_takes_its_result_off_the_blow() -> void:
	# 1 vs 5: the unarmed Lurker's vantage of 4 is its blow; the 3 takes 3 off
	var player: FightSide = _shielded(3)
	FightExchange.new(player, _lurker(5))
	assert_bool(player.raises_shield).is_true()
	assert_int(player.blow).is_equal(4)
	assert_int(player.shield_blocked).is_equal(3)
	assert_int(player.injury_taken).is_equal(1)
	assert_int(player.shield_strain).is_equal(FightSide.Strain.NONE)

func test_shield_takes_at_most_the_whole_blow() -> void:
	var player: FightSide = _shielded(6)
	FightExchange.new(player, _lurker(5))
	assert_int(player.shield_blocked).is_equal(4)
	assert_int(player.injury_taken).is_equal(0)

func test_no_blow_no_raise() -> void:
	var player: FightSide = _shielded(3, [6] as Array[int])
	FightExchange.new(player, _lurker(2))
	assert_bool(player.raises_shield).is_false()
	assert_int(player.blow).is_equal(0)

func test_shield_beyond_guts_is_only_raised_when_forced() -> void:
	var player: FightSide = _shielded(6, [1] as Array[int], 5)
	FightExchange.new(player, _lurker(5))
	assert_bool(player.raises_shield).is_false()
	var forced: FightSide = _shielded(6, [1] as Array[int], 5)
	forced.shield_use = FightSide.ShieldUse.RAISE
	FightExchange.new(forced, _lurker(5))
	assert_bool(forced.raises_shield).is_true()
	assert_int(forced.shield_strain).is_equal(FightSide.Strain.OVERREACH)
	assert_int(forced.injury_taken).is_equal(0)

func test_marked_face_still_blocks() -> void:
	var player: FightSide = _shielded(3)
	player.shield_marked_faces = [3] as Array[int]
	FightExchange.new(player, _lurker(5))
	assert_int(player.shield_blocked).is_equal(3)
	assert_int(player.shield_strain).is_equal(FightSide.Strain.MARKED_FACE)

func test_lowered_shield_takes_the_blow() -> void:
	var player: FightSide = _shielded(3)
	player.shield_use = FightSide.ShieldUse.LOWER
	FightExchange.new(player, _lurker(5))
	assert_bool(player.raises_shield).is_false()
	assert_int(player.injury_taken).is_equal(4)

func test_shield_comes_after_blood_and_before_the_gambeson() -> void:
	# 6 vs 4 with Blood: the Lurker's 6 loses 2 to the vantage, 3 to the shield and 1 to the Gambeson
	var player: FightSide = FightSide.new(BLOOD, FightTestDice.dice([Rules.d6], [6]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 1))
	player.shield_dice = FightTestDice.dice([Rules.d6], [3])
	player.damage_reduction = 1
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [4]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d8, 6))
	FightExchange.new(player, lurker)
	assert_int(player.damage_avoided).is_equal(2)
	assert_int(player.shield_blocked).is_equal(3)
	assert_int(player.damage_prevented).is_equal(1)
	assert_int(player.injury_taken).is_equal(0)

func test_monsters_raise_shields_too() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d6], [5]), FightTestDice.scores(7))
	var lurker: FightSide = _lurker(1)
	lurker.shield_dice = FightTestDice.dice([Rules.d8], [2])
	FightExchange.new(player, lurker)
	assert_bool(lurker.raises_shield).is_true()
	assert_int(lurker.injury_taken).is_equal(2)

## Unarmed with a d6 shield of [param shield_result]
func _shielded(shield_result: int, breath_results: Array[int] = [1], guts: int = 7) -> FightSide:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], breath_results), FightTestDice.scores(guts))
	player.shield_dice = FightTestDice.dice([Rules.d6], [shield_result])
	return player

func _lurker(threat: int) -> FightSide:
	return FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [threat]), FightTestDice.scores(7))
