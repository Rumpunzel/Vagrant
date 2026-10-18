extends GdUnitTestSuite

## Shields: the shield die lowers the foe's highest die (breath or weapon, a tie goes to the weapon).

const GUTS: CharacterAttribute = Rules.STRENGTH

func test_shield_lowers_the_highest_breath_die() -> void:
	# The 8 drops to 4, so the Lurker's threat is its next highest die: 5
	var player: FightSide = _shielded(4, [1, 1, 2, 2, 7])
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([3, 5, 8]), FightTestDice.scores(9))
	FightExchange.new(player, lurker)
	assert_int(player.shield_target.result).is_equal(8)
	assert_int(lurker.threat).is_equal(5)
	assert_int(lurker.injury_taken).is_equal(2)

func test_lowered_die_still_counts() -> void:
	var player: FightSide = _shielded(6, [1, 1, 1, 1, 1])
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([1, 1, 8]), FightTestDice.scores(9))
	FightExchange.new(player, lurker)
	assert_int(lurker.threat).is_equal(2)

func test_tie_goes_to_the_weapon() -> void:
	var player: FightSide = _shielded(4, [1, 1, 1, 1, 1])
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([3, 4, 6]), FightTestDice.scores(9), FightTestDice.weapon(Rules.d8, 6))
	FightExchange.new(player, lurker)
	assert_bool(player.shield_target == lurker.weapon_dice[0]).is_true()
	assert_int(lurker.threat).is_equal(6)
	assert_int(lurker.weapon_damage).is_equal(2)

func test_higher_weapon_die_is_lowered() -> void:
	var player: FightSide = _shielded(5, [1, 1, 1, 1, 1])
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([1, 2, 3]), FightTestDice.scores(9), FightTestDice.weapon(Rules.d8, 7))
	FightExchange.new(player, lurker)
	assert_int(lurker.weapon_damage).is_equal(2)
	assert_int(lurker.threat).is_equal(3)

func test_losses_wielding_and_armor_use_the_rolled_face() -> void:
	# The 8 is lowered to 2, but still lost against Guts 5
	var player: FightSide = _shielded(6, [1, 1, 1, 1, 1])
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([1, 1, 8]), FightTestDice.scores(5))
	FightExchange.new(player, lurker)
	assert_array(FightTestDice.results(lurker.lost_breath_dice)).is_equal([8])
	# Sword 10 lowered to 6 by the Lurker's shield, but the helmet blocks the rolled 10
	var sword_side: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 1, 1, 1]), FightTestDice.scores(12), FightTestDice.weapon(Rules.d10, 10))
	var helmeted: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([1, 1, 1]), FightTestDice.scores(9))
	helmeted.shield_dice = FightTestDice.weapon(Rules.d6, 4)
	helmeted.armor_blocks = [5, 10] as Array[int]
	FightExchange.new(sword_side, helmeted)
	assert_array(FightTestDice.results(sword_side.blocked_weapon_dice)).is_equal([10])
	assert_int(sword_side.weapon_damage).is_equal(0)

func test_natural_weapons_are_lowered_once_for_threat_and_damage() -> void:
	var player: FightSide = _shielded(5, [1, 1, 1, 1, 1])
	var bear: FightSide = FightTestDice.natural(GUTS, [3, 4, 8], FightTestDice.scores(9))
	FightExchange.new(player, bear)
	assert_int(bear.threat).is_equal(4)
	assert_int(bear.weapon_damage).is_equal(4)

func test_shield_above_guts_is_not_raised() -> void:
	var player: FightSide = _shielded(8, [1, 1, 1, 1, 1])
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([1, 1, 6]), FightTestDice.scores(9))
	FightExchange.new(player, lurker)
	assert_array(FightTestDice.results(player.failed_shield_dice)).is_equal([8])
	assert_object(player.shield_target).is_null()
	assert_int(lurker.threat).is_equal(6)

func test_marked_shield_face_does_nothing() -> void:
	var player: FightSide = _shielded(4, [1, 1, 1, 1, 1])
	player.shield_marked_faces = [4] as Array[int]
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([1, 1, 6]), FightTestDice.scores(9))
	FightExchange.new(player, lurker)
	assert_object(player.shield_target).is_null()
	assert_int(lurker.threat).is_equal(6)

func test_shield_against_shield() -> void:
	var player: FightSide = _shielded(3, [1, 1, 2, 2, 7])
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([1, 2, 6]), FightTestDice.scores(9))
	lurker.shield_dice = FightTestDice.weapon(Rules.d6, 5)
	FightExchange.new(player, lurker)
	# Player 7 - 5 = 2 (next highest 2); Lurker 6 - 3 = 3 (next highest 2)
	assert_int(player.threat).is_equal(2)
	assert_int(lurker.threat).is_equal(3)

## Player with Guts 7 and a d8 shield that rolled [param shield_result]
func _shielded(shield_result: int, breath_results: Array[int]) -> FightSide:
	var side: FightSide = FightSide.new(GUTS, FightTestDice.player_dice(breath_results), FightTestDice.scores(7))
	side.shield_dice = FightTestDice.weapon(Rules.d8, shield_result)
	return side
