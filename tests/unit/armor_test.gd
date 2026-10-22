extends GdUnitTestSuite

## Armour: blocked results, marks and ruin, damage reduction, modifiers.

const GAMBESON: String = "uid://cgbwu4wq14rtm"  # gambeson.tres
const HELMET: String = "uid://d0vokcalj7e4j"  # helmet.tres
const CHAINMAIL: String = "uid://2lictenntcvx"  # chainmail.tres
const PLATE: String = "uid://c2rpbx77luhym"  # plate.tres
const BATTERED: String = "uid://cjt8mg5iiet5k"  # battered.tres

func test_armor_pieces() -> void:
	assert_int((load(GAMBESON) as ArmorProfile).damage_reduction).is_equal(1)
	assert_array((load(GAMBESON) as ArmorProfile).blocked_results).is_empty()
	assert_array((load(HELMET) as ArmorProfile).blocked_results).is_equal([5, 10])
	assert_array((load(CHAINMAIL) as ArmorProfile).blocked_results).is_equal([3, 6, 9, 12])
	assert_array((load(PLATE) as ArmorProfile).blocked_results).is_equal([2, 4, 6, 8, 10, 12])

func test_marked_result_still_blocks_and_marking_again_ruins() -> void:
	var helmet: Armor = Armor.create(load(HELMET))
	assert_bool(helmet.blocks(10)).is_true()
	assert_bool(helmet.blocks(7)).is_false()
	assert_int(helmet.mark(10)).is_equal(10)
	assert_bool(helmet.blocks(10)).is_true()
	# No higher result to mark instead
	assert_int(helmet.mark(10)).is_equal(0)
	assert_bool(helmet.blocks(5)).is_false()

func test_pieces_stack() -> void:
	var armor: Array[Armor] = Armor.carry([load(HELMET), load(CHAINMAIL), load(GAMBESON)] as Array[ArmorProfile])
	var blocked: Array[int] = Armor.get_blocked_results(armor)
	blocked.sort()
	assert_array(blocked).is_equal([3, 5, 6, 9, 10, 12])
	assert_int(Armor.get_total_damage_reduction(armor)).is_equal(1)

func test_ruined_pieces_stop_protecting() -> void:
	var armor: Array[Armor] = Armor.carry([load(HELMET), load(GAMBESON)] as Array[ArmorProfile])
	armor[0].ruined = true
	armor[1].ruined = true
	assert_array(Armor.get_blocked_results(armor)).is_empty()
	assert_int(Armor.get_total_damage_reduction(armor)).is_equal(0)

func test_battered_armor_marks_blockable_results() -> void:
	var armor: Array[Armor] = Armor.carry([load(HELMET), load(GAMBESON)] as Array[ArmorProfile], [load(BATTERED)] as Array[EquipmentModifier])
	assert_array(armor[0].marked_faces).is_equal([5, 10])
	assert_bool(armor[0].is_usable()).is_true()
	assert_array(armor[1].marked_faces).is_empty()
