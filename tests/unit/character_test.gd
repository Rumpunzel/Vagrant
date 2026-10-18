extends GdUnitTestSuite

## Runtime characters: breath dice, catching breath, exhaustion, injuries.

const DORIAN: String = "uid://73nsysikxf7j"  # dorian.tres
const CHARACTER: String = "uid://bl0pdxri24fnh"  # character.tscn

var _character: Character

func before_test() -> void:
	_character = auto_free(load(CHARACTER).instantiate())
	add_child(_character)
	_character.character_profile = (load(DORIAN) as CharacterProfile).duplicate(true)

func test_starts_with_all_breath_dice() -> void:
	assert_dict(_character.breath_dice).is_equal(Rules.BREATH_DICE)
	assert_array(_character.exhaustion).is_empty()

func test_lose_breath_dice() -> void:
	var lost_signals: Array = []
	_character.lost_breath.connect(func(dice: Array[Die]) -> void: lost_signals.append(dice))
	_character.lose_breath_dice([Rules.d12.get_die(), Rules.d4.get_die()] as Array[Die])
	assert_int(_character.get_breath_dice_count(Rules.d12)).is_equal(0)
	assert_int(_character.get_breath_dice_count(Rules.d4)).is_equal(0)
	assert_int(_character.get_breath_dice_count(Rules.d8)).is_equal(1)
	assert_int(lost_signals.size()).is_equal(1)
	_character.lose_breath_dice([] as Array[Die])
	assert_int(lost_signals.size()).is_equal(1)

func test_catch_breath_exhausts_one_die_and_recovers_the_rest() -> void:
	_character.lose_breath_dice([Rules.d12.get_die(), Rules.d10.get_die(), Rules.d4.get_die()] as Array[Die])
	assert_bool(_character.can_catch_breath(Rules.d4)).is_true()
	assert_dict(_character.get_recoverable_breath_dice(Rules.d4)).is_equal({Rules.d10: 1, Rules.d12: 1})
	_character.catch_breath(Rules.d4)
	assert_array(_character.exhaustion).is_equal([Rules.d4])
	assert_int(_character.get_breath_dice_count(Rules.d12)).is_equal(1)
	assert_int(_character.get_breath_dice_count(Rules.d10)).is_equal(1)
	# The exhausted die is not recovered
	assert_int(_character.get_breath_dice_count(Rules.d4)).is_equal(0)
	assert_array(_character.get_available_exhaustion()).not_contains([Rules.d4])
	assert_object(_character.get_smallest_exhaustion()).is_same(Rules.d6)

func test_cannot_catch_breath_with_nothing_to_recover() -> void:
	assert_bool(_character.can_catch_breath(Rules.d4)).is_false()
	# Losing only the die that would be exhausted leaves nothing to recover either
	_character.lose_breath_dice([Rules.d4.get_die()] as Array[Die])
	assert_bool(_character.can_catch_breath(Rules.d4)).is_false()
	assert_bool(_character.can_catch_breath(Rules.d6)).is_true()

func test_cannot_exhaust_the_last_die() -> void:
	for die_type: DieType in [Rules.d4, Rules.d6, Rules.d8, Rules.d10]:
		_character.lose_breath_dice([Rules.d12.get_die()] as Array[Die])
		_character.catch_breath(die_type)
	assert_array(_character.get_available_exhaustion()).is_equal([Rules.d12])
	_character.lose_breath_dice([Rules.d12.get_die()] as Array[Die])
	assert_bool(_character.can_catch_breath(Rules.d12)).is_false()

func test_injuries_lower_scores() -> void:
	var before: Dictionary[CharacterAttribute, int] = {}
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: before[attribute] = _character.get_attribute_score(attribute).get_score()
	_character.suffer_injury(Injury.new(2))
	_character.suffer_injury(Injury.new(1))
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		assert_int(_character.get_attribute_score(attribute).get_score()).is_equal(before[attribute] - 3)

func test_auto_selected_breath_dice_fit_the_score() -> void:
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var score: int = _character.get_attribute_score(attribute).get_score()
		var selected: Dictionary[DieType, int] = _character.get_auto_selected_breath_dice(attribute)
		for die_type: DieType in Rules.BREATH_DICE:
			assert_bool(selected.has(die_type)).is_equal(die_type.faces <= score)

func test_weapon_modifiers_shape_carried_weapons() -> void:
	var profile: CharacterProfile = (load(DORIAN) as CharacterProfile).duplicate(true)
	var battered: MarkRandomFacesModifier = MarkRandomFacesModifier.new()
	profile.weapons = [WeaponProfile.create("Club", Rules.d6), WeaponProfile.create("Knife", Rules.d8)] as Array[WeaponProfile]
	profile.weapon_modifiers = [battered] as Array[EquipmentModifier]
	_character.character_profile = profile
	assert_int(_character.weapons.size()).is_equal(2)
	for weapon: Weapon in _character.weapons: assert_int(weapon.marked_faces.size()).is_equal(2)

func test_favored_attribute() -> void:
	assert_object(_character.get_favored_attribute()).is_same(_character.get_highest_attribute())
	_character.most_recently_chosen_attribute = Rules.INTELLIGENCE
	assert_object(_character.get_favored_attribute()).is_same(Rules.INTELLIGENCE)

func test_highest_attribute() -> void:
	var highest: CharacterAttribute = _character.get_highest_attribute()
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		assert_int(_character.get_attribute_score(attribute).get_score()).is_less_equal(_character.get_attribute_score(highest).get_score())
