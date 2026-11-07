extends GdUnitTestSuite

## What characters and monsters carry: plain items in a number, gear as pieces with their own marks; gaining, losing, handing over.

const CHARACTER: String = "uid://bl0pdxri24fnh"  # character.tscn

var _character: Character
var _rations: ItemProfile
var _sword: WeaponProfile

func before_test() -> void:
	_rations = ItemProfile.create_item("Rations")
	_sword = WeaponProfile.create("Sword", Rules.d10)
	_character = _new_character(TestCharacters.adventurer())

func test_plain_items_are_carried_in_a_number() -> void:
	_character.gain(_rations, 3)
	assert_int(_character.count_of(_rations)).is_equal(3)
	assert_int(_character.lose(_rations, 2)).is_equal(2)
	assert_int(_character.count_of(_rations)).is_equal(1)
	# Losing more than is carried gives what there is
	assert_int(_character.lose(_rations, 5)).is_equal(1)
	assert_bool(_character.items.has(_rations)).is_false()

func test_gear_is_carried_as_pieces() -> void:
	var helmet: ArmorProfile = ArmorProfile.create("Helmet", [5, 10] as Array[int])
	var buckler: ShieldProfile = ShieldProfile.create("Buckler", Rules.d6)
	for item: ItemProfile in [_sword, _sword, helmet, buckler]: _character.gain(item)
	assert_int(_character.weapons.size()).is_equal(2)
	assert_object(_character.armor[0].armor_profile).is_same(helmet)
	assert_object(_character.shields[0].shield_profile).is_same(buckler)
	assert_int(_character.count_of(_sword)).is_equal(2)
	assert_bool(_character.items.is_empty()).is_true()
	# Ruined pieces are still there but no longer count
	_character.weapons[0].ruin()
	assert_int(_character.count_of(_sword)).is_equal(1)

func test_the_most_worn_piece_goes_first() -> void:
	_character.gain(_sword, 2)
	var worn: Weapon = _character.weapons[1]
	worn.mark(9)
	assert_int(_character.lose(_sword)).is_equal(1)
	assert_array(_character.weapons).not_contains([worn])
	assert_int(_character.weapons.size()).is_equal(1)

func test_handing_over_keeps_the_marks() -> void:
	var foe: Character = _new_character(TestCharacters.adventurer())
	foe.gain(_sword)
	var piece: Weapon = foe.weapons[0]
	piece.mark(7)
	foe.hand_over(piece, _character)
	assert_array(foe.weapons).is_empty()
	assert_object(_character.weapons[0]).is_same(piece)
	assert_array(_character.weapons[0].marked_faces).contains_exactly([7])

func test_gear_among_a_profiles_items_is_carried_as_pieces() -> void:
	var profile: CharacterProfile = TestCharacters.adventurer()
	profile.items = {_sword: 1, _rations: 2} as Dictionary[ItemProfile, int]
	var character: Character = _new_character(profile)
	assert_int(character.weapons.size()).is_equal(1)
	assert_dict(character.items).is_equal({_rations: 2})

func test_gaining_and_losing_are_announced() -> void:
	var changes: Array[int] = [0]
	_character.carried_changed.connect(func() -> void: changes[0] += 1)
	_character.gain(_rations)
	_character.lose(_rations)
	_character.lose(_rations)
	# Losing nothing changes nothing
	assert_int(changes[0]).is_equal(2)

func _new_character(profile: CharacterProfile) -> Character:
	var character: Character = auto_free((load(CHARACTER) as PackedScene).instantiate())
	add_child(character)
	character.character_profile = profile
	return character
