extends GdUnitTestSuite

## Looting a monster through the real Story scene: a page lists its gear and loot, one choice each; what is taken is told; searching what
## has nothing left isn't offered.

const STORY_SCENE: PackedScene = preload("uid://db6oui711vqep")  # story.tscn

var _story: Story
var _camp: AdventureLocation
var _bandit: AdventureEncounter
var _rations: ItemProfile

func before_test() -> void:
	_rations = ItemProfile.create_item("Rations")
	_bandit = AdventureEncounter.new()
	_bandit.title = "Bandit"
	_bandit.profile = TestMonsters.cutthroat()
	_bandit.loot = {_rations: 2} as Dictionary[ItemProfile, int]
	# Searching is on an event of the bandit's, so it searches its own encounter
	var search: AdventureLootDecision = AdventureLootDecision.new()
	search.description = "Search the bandit."
	var beaten: AdventureEvent = AdventureEvent.new()
	beaten.where = AdventureEvent.Where.ANYWHERE
	beaten.decisions = [search] as Array[AdventureDecision]
	_bandit.events = [beaten] as Array[AdventureEvent]
	_camp = AdventureLocation.new()
	_camp.title = "Camp"
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = _camp
	adventure.encounters = [_bandit] as Array[AdventureEncounter]
	_story = auto_free(STORY_SCENE.instantiate())
	_story._reveal_delay = 0.01
	add_child(_story)
	_story.start_adventure(adventure, TestCharacters.adventurer())

func after_test() -> void:
	await await_millis(300)

func test_taking_one_thing_at_a_time() -> void:
	var knife: Weapon = _story.get_monster(_bandit, _bandit.profile as MonsterProfile).weapons[0]
	knife.mark(3)
	await _choose("Search the bandit.")
	assert_array(_choices()).is_equal(["Take the Knife (marked 3).", "Take 2 Rations.", "Take everything.", "Leave the rest."])
	await _choose("Take the Knife (marked 3).")
	assert_str(_story._current_story_page.description).starts_with("[p][i]You gain the Knife.[/i][/p]")
	assert_object(_story.get_protagonist().weapons[0]).is_same(knife)
	assert_array(_choices()).is_equal(["Take 2 Rations.", "Leave the rest."])
	await _choose("Leave the rest.")
	assert_object(_story._current_story_page.adventure_page).is_same(_camp)
	# Something is left: still offered; taking the last of it goes on
	await _choose("Search the bandit.")
	await _choose("Take 2 Rations.")
	assert_object(_story._current_story_page.adventure_page).is_same(_camp)
	assert_str(_story._current_story_page.description).starts_with("[p][i]You gain 2 Rations.[/i][/p]")
	assert_int(_story.get_protagonist().count_of(_rations)).is_equal(2)
	assert_array(_choices()).not_contains(["Search the bandit."])

func test_taking_everything() -> void:
	await _choose("Search the bandit.")
	await _choose("Take everything.")
	assert_object(_story._current_story_page.adventure_page).is_same(_camp)
	assert_str(_story._current_story_page.description).starts_with("[p][i]You gain the Knife and 2 Rations.[/i][/p]")
	assert_array(_story.get_monster(_bandit, _bandit.profile as MonsterProfile).weapons).is_empty()

func _choices() -> Array:
	return _story._current_story_page.choices.map(func(choice: StoryChoice) -> String: return choice.get_description())

func _choose(description: String) -> void:
	var page: StoryPage = _story._current_story_page
	var index: int = _choices().find(description)
	assert_int(index).is_not_equal(-1)
	page.choices[index].chose()
	var waited: int = 0
	while _story._current_story_page == page and waited < 5000:
		await await_millis(10)
		waited += 10
