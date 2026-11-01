extends GdUnitTestSuite

## Without breath dice, saves and fights can't be chosen; with nothing else to do, the first one fails on arrival
## (a fight is lost without offering Fight/Flee).

var _lost_page: AdventurePage
var _start_page: AdventurePage

func before_test() -> void:
	_lost_page = AdventurePage.new()
	_lost_page.title = "Lost"

func after_test() -> void:
	await await_millis(500)

func test_fight_without_breath_is_lost_on_arrival() -> void:
	var fight_decision: AdventureFightDecision = _fight_decision()
	# Margin 0 must not crash the injury consequence
	fight_decision.failure_consequences = [load("uid://b2xdmgxkfx8tf")] as Array[AdventureConsequence]  # injury_consequence.tres
	var fight_page: AdventurePage = _page("Ambush", [fight_decision])
	var story: Story = _start_breathless(fight_page)
	var shown_pages: Array[AdventurePage] = []
	story.story_page_entered.connect(func(story_page: StoryPage) -> void: shown_pages.append(story_page.adventure_page))
	await _walk_to(story, _lost_page)
	assert_object(story._current_story_page.adventure_page).is_same(_lost_page)
	# The fight page is never shown, but still counts as visited
	assert_array(shown_pages).is_equal([_lost_page])
	assert_int(story.get_how_often_page_has_been_entered(fight_page)).is_equal(1)

func test_save_without_breath_fails_on_arrival() -> void:
	var story: Story = _start_breathless(_page("Ledge", [_save_decision()]))
	await _walk_to(story, _lost_page)
	assert_object(story._current_story_page.adventure_page).is_same(_lost_page)

func test_with_something_else_to_do_they_are_greyed_out() -> void:
	var leave: AdventureDecision = AdventureDecision.new()
	leave.description = "Back away"
	var page: AdventurePage = _page("Ambush", [_fight_decision(), _save_decision(), leave])
	var story: Story = _start_breathless(page)
	await _walk_to(story, page)
	var choices: Array[StoryChoice] = story._current_story_page.choices
	# Fight, flee, the save: none can be chosen; backing away can
	assert_array(choices.map(func(choice: StoryChoice) -> bool: return choice.is_available())).is_equal([false, false, false, true])
	var buttons: Array[DialogButton] = _present_buttons(story)
	assert_array(buttons.map(func(button: DialogButton) -> bool: return button.disabled)).is_equal([true, true, true, false])
	assert_str(buttons[2].tooltip_text).is_equal(StoryDiceDecision.NO_BREATH)
	# Catching breath brings them back
	story._protagonist.catch_breath(Rules.d4)
	assert_array(buttons.map(func(button: DialogButton) -> bool: return button.disabled)).is_equal([false, false, false, false])
	assert_str(buttons[2].tooltip_text).is_empty()

func _fight_decision() -> AdventureFightDecision:
	var decision: AdventureFightDecision = AdventureFightDecision.new()
	decision.description = "Fight!"
	decision.enemies = [TestMonsters.cutthroat()] as Array[MonsterProfile]
	decision.failure_transition = _lost_page
	return decision

func _save_decision() -> AdventureSaveDecision:
	var decision: AdventureSaveDecision = AdventureSaveDecision.new()
	decision.description = "Jump"
	decision.attribute = Rules.AGILITY
	decision.difficulty = 5
	decision.failure_transition = _lost_page
	return decision

func _page(title: String, decisions: Array[AdventureDecision]) -> AdventurePage:
	var page: AdventurePage = AdventurePage.new()
	page.title = title
	page.decisions = decisions
	return page

## Out of breath on a start page that leads to [param page]
func _start_breathless(page: AdventurePage) -> Story:
	var walk: AdventureDecision = AdventureDecision.new()
	walk.description = "Walk on"
	walk.transition = page
	_start_page = _page("Start", [walk])
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = _start_page
	var story: Story = auto_free(load("uid://db6oui711vqep").instantiate())  # story.tscn
	story._reveal_delay = 0.01
	add_child(story)
	story.start_adventure(adventure, TestCharacters.adventurer())
	story._protagonist.lose_breath_dice(story._protagonist.get_breath_dice_pool())
	return story

func _walk_to(story: Story, page: AdventurePage) -> void:
	story._current_story_page.choices[0].chose()
	var waited: int = 0
	while story._current_story_page.adventure_page != page and waited < 5000:
		await await_millis(10)
		waited += 10

## The buttons of the page shown now, in order
func _present_buttons(story: Story) -> Array[DialogButton]:
	var buttons: Array[DialogButton] = []
	for node: Node in story.find_children("*", "", true, false):
		if node is DialogButton and (node as DialogButton).state == StoryEntry.State.PRESENT: buttons.append(node as DialogButton)
	return buttons
