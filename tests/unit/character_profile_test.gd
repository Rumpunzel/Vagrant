extends GdUnitTestSuite

## Character profiles and origins.

const PEASANT: String = "uid://c7j5c7ekitgl3"  # peasant.tres
const BLACKSMITH: String = "uid://bm2bwleksmsqv"  # blacksmith.tres

func test_complete_profile_is_valid() -> void:
	assert_bool(TestCharacters.adventurer().is_valid()).is_true()

func test_validity_parts() -> void:
	var profile: CharacterProfile = TestCharacters.adventurer()
	profile.name = ""
	assert_bool(profile.has_valid_bio()).is_false()
	assert_bool(profile.is_valid()).is_false()
	profile = TestCharacters.adventurer()
	profile.origins = [profile.origins[0], null] as Array[Origin]
	assert_bool(profile.has_valid_origins()).is_false()
	profile.origins = [profile.origins[0]] as Array[Origin]
	assert_bool(profile.has_valid_origins()).is_false()
	profile = TestCharacters.adventurer()
	profile.attribute_scores[Rules.AGILITY] = null
	assert_bool(profile.has_valid_attributes()).is_false()

func test_new_profile_is_invalid() -> void:
	assert_bool(CharacterProfile.new().is_valid()).is_false()

func test_available_doubles() -> void:
	var profile: CharacterProfile = CharacterProfile.new()
	profile.attribute_scores = {
		Rules.STRENGTH: _rolled(3, 3),
		Rules.AGILITY: _rolled(2, 5),
		Rules.INTELLIGENCE: _rolled(6, 6),
	} as Dictionary[CharacterAttribute, RolledAttributeScore]
	assert_int(profile.get_available_doubles()).is_equal(2)

func test_attribute_modifiers_come_from_origins() -> void:
	var profile: CharacterProfile = TestCharacters.adventurer()
	var modifier: AttributeScoreModifier = AttributeScoreModifier.new()
	modifier.score_modifiers = {Rules.STRENGTH: 1, Rules.AGILITY: 0, Rules.INTELLIGENCE: -1} as Dictionary[CharacterAttribute, int]
	profile.origins[0].modifiers = [modifier] as Array[AttributeScoreModifier]
	profile.origins[1].modifiers = [modifier, modifier] as Array[AttributeScoreModifier]
	assert_int(profile.get_attribute_modifiers().size()).is_equal(3)

func test_origin_without_ass_keeps_losses() -> void:
	var origin: Origin = Origin.new()
	var lost: Array[Die] = [Die.new(Rules.d8, 7), Die.new(Rules.d12, 9)] as Array[Die]
	assert_array(origin.get_lost_breath_dice(lost)).is_equal(lost)

func test_peasant_only_loses_highest_die() -> void:
	var peasant: Origin = load(PEASANT)
	var d10: Die = Die.new(Rules.d10, 9)
	var d12: Die = Die.new(Rules.d12, 9)
	var lost: Array[Die] = [Die.new(Rules.d8, 7), d12, d10] as Array[Die]
	# On equal results the smaller die is the one lost
	assert_array(peasant.get_lost_breath_dice(lost)).is_equal([d10])
	assert_array(peasant.get_lost_breath_dice([] as Array[Die])).is_empty()

func test_origin_combination() -> void:
	var blacksmith: OriginCombination = load(BLACKSMITH)
	assert_object(OriginCombination.find_combination(blacksmith.origins)).is_same(blacksmith)
	assert_str(Origin.concatenate(blacksmith.origins)).is_equal("Blacksmith")
	assert_bool(blacksmith.fits([blacksmith.origins[0]] as Array[Origin])).is_false()

func test_concatenate_without_combination() -> void:
	var first: Origin = Origin.new()
	first.name = "First"
	var second: Origin = Origin.new()
	second.name = "Second"
	assert_str(Origin.concatenate([first, second] as Array[Origin])).is_equal("First — Second")

func _rolled(first: int, second: int) -> RolledAttributeScore:
	return RolledAttributeScore.new([Die.new(Rules.d6, first), Die.new(Rules.d6, second)] as Array[Die])
