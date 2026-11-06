extends GdUnitTestSuite

## Items through the story: gaining and losing them as effects, "carries" as a condition, the journal's record of it.

const CHARACTER: String = "uid://bl0pdxri24fnh"  # character.tscn

var _story: Story
var _rations: ItemProfile
var _sword: WeaponProfile

func before_test() -> void:
	_story = auto_free(Story.new())
	var character: Character = auto_free((load(CHARACTER) as PackedScene).instantiate())
	add_child(character)
	character.character_profile = TestCharacters.adventurer()
	_story._protagonist = character
	_rations = ItemProfile.create_item("Rations")
	_sword = WeaponProfile.create("Sword", Rules.d10)

func test_gaining_and_losing() -> void:
	_consequence(AdventureGainConsequence.new(), _rations, 3).resolve(_story, 0)
	_consequence(AdventureGainConsequence.new(), _sword, 1).resolve(_story, 0)
	assert_int(_story.get_protagonist().count_of(_rations)).is_equal(3)
	assert_int(_story.get_protagonist().weapons.size()).is_equal(1)
	_consequence(AdventureLoseConsequence.new(), _rations, 5).resolve(_story, 0)
	assert_int(_story.get_protagonist().count_of(_rations)).is_equal(0)
	# Gained twice, lost once (all three that were there)
	var entries: Array = _story.journal.entries.filter(func(entry: Dictionary) -> bool: return entry.type == "gained" or entry.type == "lost")
	assert_array(entries.map(func(entry: Dictionary) -> String: return "%s %d" % [entry.type, entry.count])).is_equal(["gained 3", "gained 1", "lost 3"])

func test_losing_what_isnt_carried_does_nothing() -> void:
	_consequence(AdventureLoseConsequence.new(), _sword, 1).resolve(_story, 0)
	assert_bool(_story.journal.entries.any(func(entry: Dictionary) -> bool: return entry.type == "lost")).is_false()

func test_carrying_as_a_condition() -> void:
	var carries: AdventureCarriesCondition = AdventureCarriesCondition.new()
	carries.item = _rations
	carries.at_least = 2
	assert_bool(carries.is_true(_story, null)).is_false()
	_story.give(_rations, 2)
	assert_bool(carries.is_true(_story, null)).is_true()
	assert_str(carries.describe()).is_equal("Carries 2 or more Rations")

func test_the_editor_names_them() -> void:
	assert_str(_consequence(AdventureGainConsequence.new(), _rations, 2).describe()).is_equal("Gain 2 Rations")
	assert_str(_consequence(AdventureLoseConsequence.new(), _sword, 1).describe()).is_equal("Lose Sword")
	assert_str(AdventureGainConsequence.new().describe()).is_equal("Gain ?")

static func _consequence(consequence: AdventureConsequence, item: ItemProfile, count: int) -> AdventureConsequence:
	consequence.set(&"item", item)
	consequence.set(&"count", count)
	return consequence
