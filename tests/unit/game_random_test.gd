extends GdUnitTestSuite

## The same seed gives the same run; a kept state goes on where it was.

func after() -> void:
	GameRandom.start()

func test_same_seed_same_rolls() -> void:
	GameRandom.start(1234)
	var first: Array[int] = _roll(20)
	GameRandom.start(1234)
	assert_array(_roll(20)).is_equal(first)
	assert_int(GameRandom.get_seed()).is_equal(1234)

func test_state_goes_on_where_it_was() -> void:
	GameRandom.start(99)
	_roll(5)
	var state: int = GameRandom.get_state()
	var next: Array[int] = _roll(10)
	GameRandom.start()
	GameRandom.set_state(state)
	assert_array(_roll(10)).is_equal(next)

func test_dice_and_chances_use_it() -> void:
	var die_type: DieType = DieType.new()
	die_type.faces = 12
	GameRandom.start(7)
	var rolls: Array[int] = []
	for _index: int in 10: rolls.append(die_type.roll(false))
	var chances: Array[bool] = []
	for _index: int in 10: chances.append(GameRandom.chance(1, 2))
	GameRandom.start(7)
	for roll: int in rolls: assert_int(die_type.roll(false)).is_equal(roll)
	for chance: bool in chances: assert_bool(GameRandom.chance(1, 2)).is_equal(chance)

func test_shuffle_keeps_items() -> void:
	GameRandom.start(5)
	var items: Array[int] = [1, 2, 3, 4, 5, 6]
	GameRandom.shuffle(items)
	assert_array(items).contains_exactly_in_any_order([1, 2, 3, 4, 5, 6])
	GameRandom.start(5)
	var again: Array[int] = [1, 2, 3, 4, 5, 6]
	GameRandom.shuffle(again)
	assert_array(again).is_equal(items)

func _roll(count: int) -> Array[int]:
	var results: Array[int] = []
	for _index: int in count: results.append(GameRandom.range_int(1, 12))
	return results
