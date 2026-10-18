extends GdUnitTestSuite

## Replays the exchanges from `Combat-Example.md` (plus rule edge cases) with fixed dice.

const GUTS: CharacterAttribute = Rules.STRENGTH
const BLOOD: CharacterAttribute = Rules.AGILITY
const NERVES: CharacterAttribute = Rules.INTELLIGENCE

func test_unarmed_exchange_1() -> void:
	var player: FightSide = FightSide.new(GUTS, _player_dice([1, 1, 2, 2, 7]), _scores(7))
	var lurker: FightSide = FightSide.new(GUTS, _lurker_dice([3, 4, 5]), _scores(5))
	FightExchange.new(player, lurker)
	assert_int(player.threat).is_equal(7)
	assert_int(lurker.threat).is_equal(5)
	assert_int(lurker.injury_taken).is_equal(2)
	assert_int(player.injury_taken).is_equal(0)
	assert_array(_results(player.lost_breath_dice)).is_empty()
	assert_array(_results(lurker.lost_breath_dice)).is_empty()

func test_unarmed_exchange_2() -> void:
	var player: FightSide = FightSide.new(GUTS, _player_dice([2, 2, 4, 7, 9]), _scores(7))
	var lurker: FightSide = FightSide.new(GUTS, _lurker_dice([3, 4, 4]), _scores(3))
	FightExchange.new(player, lurker)
	assert_int(lurker.injury_taken).is_equal(5)
	assert_int(player.injury_taken).is_equal(0)
	assert_array(_results(player.lost_breath_dice)).is_equal([9])
	assert_array(_results(lurker.lost_breath_dice)).is_equal([4, 4])

func test_armed_exchange_1() -> void:
	var player: FightSide = FightSide.new(GUTS, _player_dice([1, 1, 2, 2, 7]), _scores(7), _weapon(Rules.d10, 3))
	var lurker: FightSide = FightSide.new(GUTS, _lurker_dice([3, 4, 5]), _scores(5), _weapon(Rules.d8, 2))
	FightExchange.new(player, lurker)
	assert_int(player.injury_taken).is_equal(2)
	assert_int(lurker.injury_taken).is_equal(5)
	assert_array(_results(player.lost_breath_dice)).is_empty()
	assert_array(_results(lurker.lost_breath_dice)).is_empty()

func test_armed_exchange_2() -> void:
	var player: FightSide = FightSide.new(BLOOD, _player_dice([2, 2, 4, 7, 9]), _scores(5), _weapon(Rules.d10, 10))
	var lurker: FightSide = FightSide.new(GUTS, _lurker_dice([3, 4, 4]), _scores(0), _weapon(Rules.d8, 1))
	FightExchange.new(player, lurker)
	assert_array(_results(player.lost_breath_dice)).is_equal([7, 9])
	assert_array(_results(lurker.lost_breath_dice)).is_equal([3, 4, 4])
	assert_array(_results(player.usable_weapon_dice)).is_empty()
	assert_int(player.injury_taken).is_equal(0)
	assert_int(lurker.injury_taken).is_equal(0)

func test_tie_guts_vs_guts() -> void:
	# On a tie each side's margin is its full threat: both deal 5
	var player: FightSide = FightSide.new(GUTS, _player_dice([1, 1, 2, 2, 5]), _scores(7))
	var lurker: FightSide = FightSide.new(GUTS, _lurker_dice([3, 4, 5]), _scores(5))
	FightExchange.new(player, lurker)
	assert_int(player.injury_taken).is_equal(5)
	assert_int(lurker.injury_taken).is_equal(5)

func test_tie_guts_vs_blood() -> void:
	# Guts adds the full threat, Blood subtracts it: only the weapons hit
	var player: FightSide = FightSide.new(GUTS, _player_dice([1, 1, 2, 2, 5]), _scores(7), _weapon(Rules.d10, 3))
	var lurker: FightSide = FightSide.new(BLOOD, _lurker_dice([3, 4, 5]), _scores(7), _weapon(Rules.d8, 2))
	FightExchange.new(player, lurker)
	assert_int(lurker.injury_taken).is_equal(3)
	assert_int(player.injury_taken).is_equal(2)

func test_tie_blood_vs_blood() -> void:
	var player: FightSide = FightSide.new(BLOOD, _player_dice([1, 1, 2, 2, 5]), _scores(7), _weapon(Rules.d10, 3))
	var lurker: FightSide = FightSide.new(BLOOD, _lurker_dice([3, 4, 5]), _scores(7), _weapon(Rules.d8, 2))
	FightExchange.new(player, lurker)
	assert_int(player.injury_taken).is_equal(0)
	assert_int(lurker.injury_taken).is_equal(0)

func test_tie_nerves() -> void:
	# Nerves impairs the Lurker's Guts by the full threat (7 -> 2): it loses its 3, 4 and 5, but its weapon 2 still works
	var player: FightSide = FightSide.new(NERVES, _player_dice([1, 1, 2, 2, 5]), _scores(7), _weapon(Rules.d10, 3), false, GUTS)
	var lurker: FightSide = FightSide.new(GUTS, _lurker_dice([3, 4, 5]), _scores(7), _weapon(Rules.d8, 2))
	FightExchange.new(player, lurker)
	assert_int(lurker.get_score(GUTS)).is_equal(2)
	assert_array(_results(lurker.lost_breath_dice)).is_equal([3, 4, 5])
	assert_array(_results(lurker.usable_weapon_dice)).is_equal([2])
	assert_int(lurker.injury_taken).is_equal(3)
	assert_int(player.injury_taken).is_equal(7)

func test_unarmed_always_guts() -> void:
	# Without a weapon there is no stance choice: Blood is overridden by Guts
	var player: FightSide = FightSide.new(BLOOD, _player_dice([1, 1, 2, 2, 7]), _scores(7))
	var lurker: FightSide = FightSide.new(GUTS, _lurker_dice([3, 4, 5]), _scores(5))
	FightExchange.new(player, lurker)
	assert_object(player.stance).is_same(GUTS)
	assert_int(lurker.injury_taken).is_equal(2)

func test_failed_flee() -> void:
	# Fleeing rolls against Blood (2): the 3 is lost; threat 3 < 5, so the difference is taken
	var player: FightSide = FightSide.new(GUTS, _dice([Rules.d4, Rules.d6], [1, 3]), _scores(7, 2), [], true)
	var lurker: FightSide = FightSide.new(GUTS, _lurker_dice([3, 4, 5]), _scores(5))
	FightExchange.new(player, lurker)
	assert_object(player.stance).is_same(BLOOD)
	assert_int(player.injury_taken).is_equal(2)
	assert_int(lurker.injury_taken).is_equal(0)
	assert_array(_results(player.lost_breath_dice)).is_equal([3])

func test_armed_flee() -> void:
	# Successful flee still takes the foe's weapon, reduced by the Blood margin; deals own weapon, no bonus
	var player: FightSide = FightSide.new(GUTS, _dice([Rules.d4, Rules.d6, Rules.d8], [1, 2, 7]), _scores(7), _weapon(Rules.d10, 3), true)
	var lurker: FightSide = FightSide.new(GUTS, _lurker_dice([3, 4, 5]), _scores(5), _weapon(Rules.d8, 4))
	FightExchange.new(player, lurker)
	assert_int(player.injury_taken).is_equal(2)
	assert_int(lurker.injury_taken).is_equal(3)

func test_nerves() -> void:
	# Nerves margin 5 on the Lurker's Guts (5 -> 0): it loses all breath dice and its weapon
	var player: FightSide = FightSide.new(NERVES, _player_dice([1, 2, 4, 7, 9]), _scores(7), _weapon(Rules.d10, 3), false, GUTS)
	var lurker: FightSide = FightSide.new(GUTS, _lurker_dice([3, 4, 4]), _scores(5), _weapon(Rules.d8, 2))
	FightExchange.new(player, lurker)
	assert_int(lurker.get_score(GUTS)).is_equal(0)
	assert_array(_results(lurker.lost_breath_dice)).is_equal([3, 4, 4])
	assert_array(_results(lurker.usable_weapon_dice)).is_empty()
	assert_array(_results(player.lost_breath_dice)).is_equal([9])
	assert_int(lurker.injury_taken).is_equal(3)
	assert_int(player.injury_taken).is_equal(0)

func _scores(guts: int, blood: int = guts, nerves: int = guts) -> Dictionary[CharacterAttribute, int]:
	return {GUTS: guts, BLOOD: blood, NERVES: nerves}

func _player_dice(results: Array[int]) -> Array[Die]:
	return _dice([Rules.d4, Rules.d6, Rules.d8, Rules.d10, Rules.d12], results)

func _lurker_dice(results: Array[int]) -> Array[Die]:
	return _dice([Rules.d8, Rules.d8, Rules.d8], results)

func _weapon(die_type: DieType, result: int) -> Array[Die]:
	return _dice([die_type], [result])

func _dice(die_types: Array[DieType], results: Array[int]) -> Array[Die]:
	assert(die_types.size() == results.size())
	var dice: Array[Die] = []
	for index: int in die_types.size(): dice.append(Die.new(die_types[index], results[index]))
	return dice

func _results(dice: Array[Die]) -> Array[int]:
	var results: Array[int] = []
	for die: Die in dice: results.append(die.result)
	return results
