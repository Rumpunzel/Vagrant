extends GdUnitTestSuite

## Vantage (how much a side won the threat by) and abilities that change it, e.g. the Veteran's double vantage.

const GUTS: CharacterAttribute = Rules.STRENGTH
const BLOOD: CharacterAttribute = Rules.AGILITY
const NERVES: CharacterAttribute = Rules.INTELLIGENCE

func test_double_vantage_with_guts_adds_twice_the_difference() -> void:
	# 6 vs 2: vantage 4, doubled 8, on top of the weapon's 4
	assert_int(_armed_against_unarmed(GUTS, false).second.injury_taken).is_equal(8)
	assert_int(_armed_against_unarmed(GUTS, true).second.injury_taken).is_equal(12)
	assert_int(_armed_against_unarmed(GUTS, true).first.damage_added).is_equal(8)

func test_double_vantage_with_nerves_impairs_twice_as_much() -> void:
	assert_dict(_armed_against_unarmed(NERVES, false).second.impairments).is_equal({GUTS: 4})
	assert_dict(_armed_against_unarmed(NERVES, true).second.impairments).is_equal({GUTS: 8})

func test_double_vantage_with_blood_takes_twice_as_much_off() -> void:
	# The foe's 9 is lowered by 4, or by 8 with double vantage
	assert_int(_blood_against_armed(false).first.injury_taken).is_equal(5)
	assert_int(_blood_against_armed(true).first.injury_taken).is_equal(1)
	assert_int(_blood_against_armed(true).first.damage_avoided).is_equal(8)

func test_tie_gives_no_vantage_to_double() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d6], [5]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 1))
	player.abilities = [VantageMultiplierAbility.new()] as Array[Ability]
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [5]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d8, 1))
	var exchange: FightExchange = FightExchange.new(player, opponent)
	# A tie is no vantage: each side's stance works with its full threat (5), the veteran's too
	assert_int(exchange.second.injury_taken).is_equal(1 + 5)
	assert_int(exchange.first.injury_taken).is_equal(1 + 5)

func test_losing_side_has_no_vantage_to_double() -> void:
	var player: FightSide = FightSide.new(BLOOD, FightTestDice.dice([Rules.d6], [2]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 1))
	player.abilities = [VantageMultiplierAbility.new()] as Array[Ability]
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [6]), FightTestDice.scores(10), FightTestDice.weapon(Rules.d10, 9))
	# The foe's 9 threatens too: 9 vs 2
	var exchange: FightExchange = FightExchange.new(player, opponent)
	assert_int(exchange.first.injury_taken).is_equal(9 + 7)

func _armed_against_unarmed(stance: CharacterAttribute, double_vantage: bool) -> FightExchange:
	var player: FightSide = FightSide.new(stance, FightTestDice.dice([Rules.d6], [6]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 4), false, GUTS)
	if double_vantage: player.abilities = [VantageMultiplierAbility.new()] as Array[Ability]
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [2]), FightTestDice.scores(7))
	return FightExchange.new(player, opponent)

func _blood_against_armed(double_vantage: bool) -> FightExchange:
	var player: FightSide = FightSide.new(BLOOD, FightTestDice.dice([Rules.d6], [5]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 1))
	if double_vantage: player.abilities = [VantageMultiplierAbility.new()] as Array[Ability]
	# Forcing the 9 one over Guts 8 costs the foe 1 threat: 5 vs 1
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [2]), FightTestDice.scores(8), FightTestDice.weapon(Rules.d10, 9))
	opponent.chosen_weapon_die = opponent.weapon_dice[0]
	return FightExchange.new(player, opponent)
