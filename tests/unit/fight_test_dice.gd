class_name FightTestDice
extends RefCounted

## Fixed dice and scores for fight exchange tests.

const GUTS: CharacterAttribute = Rules.STRENGTH
const BLOOD: CharacterAttribute = Rules.AGILITY
const NERVES: CharacterAttribute = Rules.INTELLIGENCE

static func natural(stance: CharacterAttribute, results: Array[int], scores: Dictionary[CharacterAttribute, int]) -> FightSide:
	var breath_dice: Array[Die] = FightTestDice.lurker_dice(results)
	var side: FightSide = FightSide.new(stance, breath_dice, scores, breath_dice)
	side.has_natural_weapons = true
	return side

static func scores(guts: int, blood: int = guts, nerves: int = guts) -> Dictionary[CharacterAttribute, int]:
	return {GUTS: guts, BLOOD: blood, NERVES: nerves}

static func player_dice(results: Array[int]) -> Array[Die]:
	return FightTestDice.dice([Rules.d4, Rules.d6, Rules.d8, Rules.d10, Rules.d12], results)

static func lurker_dice(results: Array[int]) -> Array[Die]:
	return FightTestDice.dice([Rules.d8, Rules.d8, Rules.d8], results)

static func weapon(die_type: DieType, result: int) -> Array[Die]:
	return FightTestDice.dice([die_type], [result])

static func dice(die_types: Array[DieType], results: Array[int]) -> Array[Die]:
	assert(die_types.size() == results.size())
	var dice: Array[Die] = []
	for index: int in die_types.size(): dice.append(Die.new(die_types[index], results[index]))
	return dice

static func results(dice: Array[Die]) -> Array[int]:
	var results: Array[int] = []
	for die: Die in dice: results.append(die.result)
	return results
