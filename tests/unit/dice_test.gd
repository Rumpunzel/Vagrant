extends GdUnitTestSuite

## Dice, die types and dice results.

const ROLLS: int = 200

func test_die_type_rolls_within_faces() -> void:
	for die_type: DieType in Rules.BREATH_DICE:
		var seen: Dictionary[int, bool] = {}
		for _roll: int in ROLLS:
			var result: int = die_type.roll(false)
			assert_int(result).is_between(1, die_type.faces)
			seen[result] = true
		# 200 rolls hit every face of a d12 with overwhelming probability
		assert_int(seen.size()).is_equal(die_type.faces)

func test_die_roll_stores_result() -> void:
	var die: Die = Rules.d6.get_die()
	var result: int = die.roll(false)
	assert_int(die.result).is_equal(result)
	assert_object(die.die_type).is_same(Rules.d6)

func test_die_type_auto_selection_against_score() -> void:
	var score: AttributeScore = AttributeScore.create(Rules.STRENGTH, _dice([Rules.d6, Rules.d6], [4, 4]))
	assert_bool(Rules.d8.is_auto_selected(score)).is_true()
	assert_bool(Rules.d10.is_auto_selected(score)).is_false()

func test_die_type_ordering() -> void:
	var die_types: Array[DieType] = [Rules.d12, Rules.d4, Rules.d8]
	die_types.sort_custom(DieType.compare_ascending)
	assert_array(die_types).is_equal([Rules.d4, Rules.d8, Rules.d12])
	die_types.sort_custom(DieType.compare_descending)
	assert_array(die_types).is_equal([Rules.d12, Rules.d8, Rules.d4])

func test_generate_dice_pool() -> void:
	var pool: Array[Die] = DiceRoller.generate_dice_pool({Rules.d4: 2, Rules.d8: 1})
	assert_int(pool.size()).is_equal(3)
	assert_int(pool.filter(func(die: Die) -> bool: return die.die_type == Rules.d4).size()).is_equal(2)

func test_roll_dice_rolls_every_die() -> void:
	var pool: Array[Die] = DiceRoller.roll_dice(Rules.d6.get_dice_pool(5), false)
	for die: Die in pool: assert_int(die.result).is_between(1, 6)

func test_dice_result_sum_and_highest() -> void:
	var result: RolledAttributeScore = RolledAttributeScore.new(_dice([Rules.d6, Rules.d6, Rules.d8], [2, 5, 5]))
	assert_int(result.get_sum()).is_equal(12)
	assert_int(result.get_highest_result()).is_equal(5)
	assert_int(result.get_highest_dice().size()).is_equal(2)
	assert_str(result.format_sum()).is_equal("[ 2 + 5 + 5 ] = 12")

func test_empty_dice_result() -> void:
	var result: RolledAttributeScore = RolledAttributeScore.new()
	assert_int(result.get_sum()).is_equal(0)
	assert_int(result.get_highest_result()).is_equal(0)
	assert_array(result.get_highest_dice()).is_empty()

func test_rolled_attribute_score_doubles() -> void:
	assert_int(RolledAttributeScore.new(_dice([Rules.d6, Rules.d6], [3, 3])).get_type()).is_equal(AttributeScore.Type.DOUBLE)
	assert_int(RolledAttributeScore.new(_dice([Rules.d6, Rules.d6], [3, 4])).get_type()).is_equal(AttributeScore.Type.NORMAL)
	assert_int(RolledAttributeScore.new().get_type()).is_equal(AttributeScore.Type.NORMAL)

func test_roll_attribute_is_2d6() -> void:
	for _roll: int in ROLLS:
		var score: RolledAttributeScore = DiceRoller.roll_attribute()
		assert_int(score.dice.size()).is_equal(2)
		assert_int(score.get_score()).is_between(2, 12)

func _dice(die_types: Array[DieType], results: Array[int]) -> Array[Die]:
	var dice: Array[Die] = []
	for index: int in die_types.size(): dice.append(Die.new(die_types[index], results[index]))
	return dice
