extends GdUnitTestSuite

## Attribute scores: rolled base plus internal (origins) and external (injuries) modifiers.

func test_score_adds_modifiers() -> void:
	var base: RolledAttributeScore = _rolled(3, 4)
	var bonus: AttributeScore.Modifier = _modifier({Rules.STRENGTH: 2, Rules.AGILITY: 0, Rules.INTELLIGENCE: 0})
	var injury: AttributeScore.Modifier = Injury.new(3).to_attribute_score_modifier()
	var score: AttributeScore = AttributeScore.new(Rules.STRENGTH, base, [bonus], [injury])
	assert_int(score.get_internal_modifier_sum()).is_equal(2)
	assert_int(score.get_external_modifier_sum()).is_equal(-3)
	assert_int(score.get_score()).is_equal(7 + 2 - 3)

func test_modifier_only_applies_to_its_attribute() -> void:
	var bonus: AttributeScore.Modifier = _modifier({Rules.STRENGTH: 2, Rules.AGILITY: 0, Rules.INTELLIGENCE: 0})
	assert_int(AttributeScore.new(Rules.AGILITY, _rolled(3, 4), [bonus]).get_score()).is_equal(7)

func test_injury_reduces_every_attribute() -> void:
	var injury: AttributeScore.Modifier = Injury.new(2).to_attribute_score_modifier()
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		assert_int(AttributeScore.new(attribute, _rolled(3, 4), [], [injury]).get_score()).is_equal(5)

func test_color_follows_external_modifiers() -> void:
	assert_object(AttributeScore.new(Rules.STRENGTH, _rolled(3, 4), []).get_color()).is_equal(Color.WHITE)
	var injury: AttributeScore.Modifier = Injury.new(1).to_attribute_score_modifier()
	assert_object(AttributeScore.new(Rules.STRENGTH, _rolled(3, 4), [], [injury]).get_color()).is_equal(Main.FAILURE)

func test_details_mark_doubles() -> void:
	assert_str(AttributeScore.new(Rules.STRENGTH, _rolled(3, 3), []).get_details()).starts_with("[color=gold]")
	assert_str(AttributeScore.new(Rules.STRENGTH, _rolled(3, 4), []).get_details()).not_contains("gold")

func test_modifier_details_sign_and_color() -> void:
	var modifier: AttributeScoreModifier = AttributeScoreModifier.new()
	modifier.score_modifiers = {Rules.STRENGTH: -2, Rules.AGILITY: 1, Rules.INTELLIGENCE: 0} as Dictionary[CharacterAttribute, int]
	assert_str(modifier.get_details(Rules.STRENGTH, null, 16, false)).is_equal("- [color=%s]2[/color]" % Main.FAILURE.to_html())
	assert_str(modifier.get_details(Rules.AGILITY, null, 16, false)).is_equal("+ [color=%s]1[/color]" % Main.SUCCESS.to_html())

func _rolled(first: int, second: int) -> RolledAttributeScore:
	return RolledAttributeScore.new([Die.new(Rules.d6, first), Die.new(Rules.d6, second)] as Array[Die])

func _modifier(score_modifiers: Dictionary[CharacterAttribute, int]) -> AttributeScore.Modifier:
	var modifier: AttributeScoreModifier = AttributeScoreModifier.new()
	modifier.score_modifiers = score_modifiers
	return AttributeScore.Modifier.new(modifier, null, false)
