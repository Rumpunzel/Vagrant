extends GdUnitTestSuite

## Replays the exchanges from `Combat-Example.md` (plus rule edge cases) with fixed dice.

const GUTS: CharacterAttribute = Rules.STRENGTH
const BLOOD: CharacterAttribute = Rules.AGILITY
const NERVES: CharacterAttribute = Rules.INTELLIGENCE

func test_unarmed_exchange_1() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 2, 2, 7]), FightTestDice.scores(7))
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([3, 4, 5]), FightTestDice.scores(5))
	FightExchange.new(player, lurker)
	assert_int(player.threat).is_equal(7)
	assert_int(lurker.threat).is_equal(5)
	assert_int(lurker.injury_taken).is_equal(2)
	assert_int(player.injury_taken).is_equal(0)
	assert_array(FightTestDice.results(player.lost_breath_dice)).is_empty()
	assert_array(FightTestDice.results(lurker.lost_breath_dice)).is_empty()

func test_unarmed_exchange_2() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([2, 2, 4, 7, 9]), FightTestDice.scores(7))
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([3, 4, 4]), FightTestDice.scores(3))
	FightExchange.new(player, lurker)
	assert_int(lurker.injury_taken).is_equal(5)
	assert_int(player.injury_taken).is_equal(0)
	assert_array(FightTestDice.results(player.lost_breath_dice)).is_equal([9])
	assert_array(FightTestDice.results(lurker.lost_breath_dice)).is_equal([4, 4])

func test_armed_exchange_1() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 2, 2, 7]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 3))
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([3, 4, 5]), FightTestDice.scores(5), FightTestDice.weapon(Rules.d8, 2))
	FightExchange.new(player, lurker)
	assert_int(player.injury_taken).is_equal(2)
	assert_int(lurker.injury_taken).is_equal(5)
	assert_array(FightTestDice.results(player.lost_breath_dice)).is_empty()
	assert_array(FightTestDice.results(lurker.lost_breath_dice)).is_empty()

func test_armed_exchange_2() -> void:
	var player: FightSide = FightSide.new(BLOOD, FightTestDice.player_dice([2, 2, 4, 7, 9]), FightTestDice.scores(5), FightTestDice.weapon(Rules.d10, 10))
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([3, 4, 4]), FightTestDice.scores(0), FightTestDice.weapon(Rules.d8, 1))
	FightExchange.new(player, lurker)
	assert_array(FightTestDice.results(player.lost_breath_dice)).is_equal([7, 9])
	assert_array(FightTestDice.results(lurker.lost_breath_dice)).is_equal([3, 4, 4])
	assert_array(FightTestDice.results(player.usable_weapon_dice)).is_empty()
	assert_int(player.injury_taken).is_equal(0)
	assert_int(lurker.injury_taken).is_equal(0)

func test_tie_guts_vs_guts() -> void:
	# On a tie each side's stance works with its full threat: both deal 5
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 2, 2, 5]), FightTestDice.scores(7))
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([3, 4, 5]), FightTestDice.scores(5))
	FightExchange.new(player, lurker)
	assert_int(player.injury_taken).is_equal(5)
	assert_int(lurker.injury_taken).is_equal(5)

func test_tie_guts_vs_blood() -> void:
	# Guts adds the full threat, Blood subtracts it: only the weapons hit
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 2, 2, 5]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 3))
	var lurker: FightSide = FightSide.new(BLOOD, FightTestDice.lurker_dice([3, 4, 5]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d8, 2))
	FightExchange.new(player, lurker)
	assert_int(lurker.injury_taken).is_equal(3)
	assert_int(player.injury_taken).is_equal(2)

func test_tie_blood_vs_blood() -> void:
	var player: FightSide = FightSide.new(BLOOD, FightTestDice.player_dice([1, 1, 2, 2, 5]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 3))
	var lurker: FightSide = FightSide.new(BLOOD, FightTestDice.lurker_dice([3, 4, 5]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d8, 2))
	FightExchange.new(player, lurker)
	assert_int(player.injury_taken).is_equal(0)
	assert_int(lurker.injury_taken).is_equal(0)

func test_tie_nerves() -> void:
	# Nerves impairs the Lurker's Guts by the full threat (7 -> 2): it loses its 3, 4 and 5, but its weapon 2 still works
	var player: FightSide = FightSide.new(NERVES, FightTestDice.player_dice([1, 1, 2, 2, 5]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 3), false, GUTS)
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([3, 4, 5]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d8, 2))
	FightExchange.new(player, lurker)
	assert_int(lurker.get_score(GUTS)).is_equal(2)
	assert_array(FightTestDice.results(lurker.lost_breath_dice)).is_equal([3, 4, 5])
	assert_array(FightTestDice.results(lurker.usable_weapon_dice)).is_equal([2])
	assert_int(lurker.injury_taken).is_equal(3)
	assert_int(player.injury_taken).is_equal(7)

func test_unarmed_always_guts() -> void:
	# Without a weapon there is no stance choice: Blood is overridden by Guts
	var player: FightSide = FightSide.new(BLOOD, FightTestDice.player_dice([1, 1, 2, 2, 7]), FightTestDice.scores(7))
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([3, 4, 5]), FightTestDice.scores(5))
	FightExchange.new(player, lurker)
	assert_object(player.stance).is_same(GUTS)
	assert_int(lurker.injury_taken).is_equal(2)

func test_failed_flee() -> void:
	# Fleeing rolls against Blood (2): the 3 is lost; threat 3 < 5, so the difference is taken
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4, Rules.d6], [1, 3]), FightTestDice.scores(7, 2), [], true)
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([3, 4, 5]), FightTestDice.scores(5))
	FightExchange.new(player, lurker)
	assert_object(player.stance).is_same(BLOOD)
	assert_int(player.injury_taken).is_equal(2)
	assert_int(lurker.injury_taken).is_equal(0)
	assert_array(FightTestDice.results(player.lost_breath_dice)).is_equal([3])

func test_armed_flee() -> void:
	# Successful flee still takes the foe's weapon, reduced by the Blood vantage; deals own weapon, no bonus
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4, Rules.d6, Rules.d8], [1, 2, 7]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 3), true)
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([3, 4, 5]), FightTestDice.scores(5), FightTestDice.weapon(Rules.d8, 4))
	FightExchange.new(player, lurker)
	assert_int(player.injury_taken).is_equal(2)
	assert_int(lurker.injury_taken).is_equal(3)

func test_nerves() -> void:
	# Nerves vantage 5 on the Lurker's Guts (5 -> 0): it loses all breath dice and its weapon
	var player: FightSide = FightSide.new(NERVES, FightTestDice.player_dice([1, 2, 4, 7, 9]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 3), false, GUTS)
	var lurker: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([3, 4, 4]), FightTestDice.scores(5), FightTestDice.weapon(Rules.d8, 2))
	FightExchange.new(player, lurker)
	assert_int(lurker.get_score(GUTS)).is_equal(0)
	assert_array(FightTestDice.results(lurker.lost_breath_dice)).is_equal([3, 4, 4])
	assert_array(FightTestDice.results(lurker.usable_weapon_dice)).is_empty()
	assert_array(FightTestDice.results(player.lost_breath_dice)).is_equal([9])
	assert_int(lurker.injury_taken).is_equal(3)
	assert_int(player.injury_taken).is_equal(0)
