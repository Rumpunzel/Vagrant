extends GdUnitTestSuite

## Which weapon die strikes: the best free one by default, or the one chosen (forced if need be), with fixed dice.

const GUTS: CharacterAttribute = Rules.STRENGTH

func test_marked_face_needs_forcing() -> void:
	var player: FightSide = _player_with_weapon(4, [4] as Array[int])
	_resolve(player)
	assert_array(player.usable_weapon_dice).is_empty()
	assert_array(FightTestDice.results(player.failed_weapon_dice)).is_equal([4])
	assert_int(player.weapon_damage).is_equal(0)

func test_forced_marked_face_strikes() -> void:
	var player: FightSide = _player_with_weapon(4, [4] as Array[int])
	player.chosen_weapon_die = player.weapon_dice[0]
	_resolve(player)
	assert_int(player.weapon_damage).is_equal(4)
	assert_int(player.weapon_strain).is_equal(FightSide.Strain.MARKED_FACE)

func test_forcing_beyond_guts_strikes_and_overreaches() -> void:
	var player: FightSide = _player_with_weapon(8, [] as Array[int], 5)
	player.chosen_weapon_die = player.weapon_dice[0]
	_resolve(player)
	assert_int(player.weapon_damage).is_equal(8)
	assert_int(player.weapon_strain).is_equal(FightSide.Strain.OVERREACH)

func test_holding_back_strikes_with_nothing() -> void:
	var player: FightSide = _player_with_weapon(3)
	player.holds_back = true
	_resolve(player)
	assert_array(player.usable_weapon_dice).is_empty()
	assert_int(player.weapon_damage).is_equal(0)

func test_of_several_weapon_dice_the_highest_free_one_strikes() -> void:
	var player: FightSide = _two_weapon_dice([3, 6], 7)
	assert_array(player.usable_weapon_dice).contains_same_exactly(player.weapon_dice[1])
	assert_array(player.spare_weapon_dice).contains_same_exactly(player.weapon_dice[0])
	assert_int(player.weapon_damage).is_equal(6)
	assert_int(player.weapon_strain).is_equal(FightSide.Strain.NONE)

func test_a_die_beyond_guts_is_left_unless_chosen() -> void:
	var player: FightSide = _two_weapon_dice([9, 4], 7)
	assert_int(player.weapon_damage).is_equal(4)
	assert_array(player.failed_weapon_dice).contains_same_exactly(player.weapon_dice[0])

func test_with_nothing_free_nothing_strikes() -> void:
	var player: FightSide = _two_weapon_dice([9, 6], 7, [6] as Array[int])
	assert_array(player.usable_weapon_dice).is_empty()
	assert_int(player.failed_weapon_dice.size()).is_equal(2)
	assert_int(player.weapon_damage).is_equal(0)

func test_free_means_after_being_unnerved() -> void:
	# The foe's Nerves win by 2: Guts 7 counts as 5, so the 6 needs forcing and the 4 strikes
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(7), FightTestDice.dice([Rules.d10, Rules.d10], [6, 4]))
	var opponent: FightSide = FightSide.new(Rules.INTELLIGENCE, FightTestDice.dice([Rules.d8], [3]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d8, 1), false, GUTS)
	FightExchange.new(player, opponent)
	assert_int(player.weapon_damage).is_equal(4)
	assert_array(player.failed_weapon_dice).contains_same_exactly(player.weapon_dice[0])

func test_marked_face_is_skipped() -> void:
	var player: FightSide = _two_weapon_dice([6, 4], 7, [6] as Array[int])
	assert_int(player.weapon_damage).is_equal(4)

func test_armour_blocked_result_is_skipped() -> void:
	var player: FightSide = _two_weapon_dice([5, 4], 7, [] as Array[int], [5] as Array[int])
	assert_int(player.weapon_damage).is_equal(4)
	assert_array(player.blocked_weapon_dice).is_empty()

func test_a_chosen_free_die_strikes_instead_of_the_best() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(7), FightTestDice.dice([Rules.d10, Rules.d10], [3, 6]))
	player.chosen_weapon_die = player.weapon_dice[0]
	_resolve(player)
	assert_int(player.weapon_damage).is_equal(3)
	assert_int(player.weapon_strain).is_equal(FightSide.Strain.NONE)

## Against an unarmed foe; the tests look at the weapon die alone, before any stance adds to it
func _resolve(player: FightSide) -> void:
	FightExchange.new(player, FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [1]), FightTestDice.scores(7)))

## The player rolls a d4 breath die of 1 and two d10 weapon dice against an unarmed foe with a 1,
## the player's weapon marked on [param marked_faces], the foe's armour blocking [param armor_blocks]
func _two_weapon_dice(results: Array[int], guts: int, marked_faces: Array[int] = [], armor_blocks: Array[int] = []) -> FightSide:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(guts), FightTestDice.dice([Rules.d10, Rules.d10], results))
	player.marked_faces = marked_faces
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [1]), FightTestDice.scores(7))
	opponent.armor_blocks = armor_blocks
	FightExchange.new(player, opponent)
	return player

## One d8 weapon die of [param result], with breath dice that can't win the threat
func _player_with_weapon(result: int, marked_faces: Array[int] = [], guts: int = 7) -> FightSide:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(guts), FightTestDice.weapon(Rules.d8, result))
	player.marked_faces = marked_faces
	return player
