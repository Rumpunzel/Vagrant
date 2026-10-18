extends GdUnitTestSuite

## Shields as content and as carried equipment.

const BUCKLER: String = "uid://drsjitqot54x4"  # buckler.tres
const ROUND_SHIELD: String = "uid://dmudbdpyppc8x"  # round_shield.tres
const KITE_SHIELD: String = "uid://kfolwptn4h8"  # kite_shield.tres
const PAVISE: String = "uid://dq1f5nyt53vmm"  # pavise.tres
const BATTERED: String = "uid://cjt8mg5iiet5k"  # battered.tres

func test_shields() -> void:
	var expected: Dictionary[String, DieType] = {BUCKLER: Rules.d6, ROUND_SHIELD: Rules.d8, KITE_SHIELD: Rules.d10, PAVISE: Rules.d12}
	for path: String in expected:
		var shield: ShieldProfile = load(path)
		assert_object(shield.die).is_same(expected[path])
		assert_object(shield.wield_attribute).is_same(Rules.STRENGTH)

func test_marking_and_ruin() -> void:
	var buckler: Shield = Shield.create(load(BUCKLER))
	assert_int(buckler.mark(6)).is_equal(Equipment.Mark.MARKED)
	assert_int(buckler.mark(6)).is_equal(Equipment.Mark.RUINED)
	assert_bool(buckler.is_usable()).is_false()

func test_first_usable_and_modifiers() -> void:
	var shields: Array[Shield] = Shield.carry([load(BUCKLER), load(PAVISE)] as Array[ShieldProfile], [load(BATTERED)] as Array[EquipmentModifier])
	for shield: Shield in shields: assert_int(shield.marked_faces.size()).is_equal(2)
	shields[0].ruined = true
	assert_object(Shield.get_first_usable(shields)).is_same(shields[1])
