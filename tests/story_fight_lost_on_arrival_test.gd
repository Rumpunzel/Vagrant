extends GdUnitTestSuite

## Entering a fight without breath dice loses it immediately, without offering Fight/Flee.

func after_test() -> void:
	await await_millis(500)

func test_fight_without_breath_is_lost_on_arrival() -> void:
	var lost_page: AdventurePage = AdventurePage.new()
	lost_page._title = "Lost"
	var fight_decision: AdventureFightDecision = AdventureFightDecision.new()
	fight_decision.description = "Fight!"
	fight_decision.enemies = [load("res://characters/monsters/lurker.tres")] as Array[MonsterProfile]
	fight_decision.failure_transition = lost_page
	# Margin 0 must not crash the injury consequence
	fight_decision.failure_consequences = [load("res://adventure/decisions/consequences/injury_consequence.tres")] as Array[AdventureConsequence]
	var fight_page: AdventurePage = AdventurePage.new()
	fight_page._title = "Ambush"
	fight_page._decisions = [fight_decision] as Array[AdventureDecision]
	var walk: AdventureDecision = AdventureDecision.new()
	walk.description = "Walk on"
	walk.transition = fight_page
	var start_page: AdventurePage = AdventurePage.new()
	start_page._decisions = [walk] as Array[AdventureDecision]
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = start_page

	var story: Story = auto_free(load("res://story/story.tscn").instantiate())
	story._reveal_delay = 0.01
	add_child(story)
	story.start_adventure(adventure, (load("res://characters/dorian.tres") as CharacterProfile).duplicate(true))
	story._protagonist.lose_breath_dice(story._protagonist.get_breath_dice_pool())
	var shown_pages: Array[AdventurePage] = []
	story.story_page_entered.connect(func(story_page: StoryPage) -> void: shown_pages.append(story_page.adventure_page))
	story._current_story_page.choices[0].chose()

	var waited: int = 0
	while story._current_story_page.adventure_page != lost_page and waited < 5000:
		await await_millis(10)
		waited += 10
	assert_object(story._current_story_page.adventure_page).is_same(lost_page)
	# The fight page is never shown, but still counts as visited
	assert_array(shown_pages).is_equal([lost_page])
	assert_int(story.get_how_often_page_has_been_entered(fight_page)).is_equal(1)
