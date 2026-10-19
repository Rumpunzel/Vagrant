extends GdUnitTestSuite

## Plays a fight through the real Story scene: fight/flee choices, exchange pages, outcome transitions.

const MAX_EXCHANGES: int = 40

var _story: Story
var _fight_page: AdventurePage
var _outcome_pages: Dictionary[AdventurePage, Fight.Outcome]

func before_test() -> void:
	var decision: AdventureFightDecision = AdventureFightDecision.new()
	decision.description = "Fight!"
	decision.flee_description = "Wun away!"
	decision.enemies = [TestMonsters.cutthroat()] as Array[MonsterProfile]
	_outcome_pages = {}
	for outcome: Fight.Outcome in [Fight.Outcome.WON, Fight.Outcome.LOST, Fight.Outcome.DRAW, Fight.Outcome.FLED]:
		var page: AdventurePage = AdventurePage.new()
		page._title = Fight.Outcome.find_key(outcome)
		_outcome_pages[page] = outcome
	decision.transition = _outcome_pages.find_key(Fight.Outcome.WON)
	decision.failure_transition = _outcome_pages.find_key(Fight.Outcome.LOST)
	decision.draw_transition = _outcome_pages.find_key(Fight.Outcome.DRAW)
	decision.flee_transition = _outcome_pages.find_key(Fight.Outcome.FLED)
	_fight_page = AdventurePage.new()
	_fight_page._title = "Ambush"
	_fight_page._decisions = [decision] as Array[AdventureDecision]
	var adventure: Adventure = Adventure.new()
	adventure.title = "Test"
	adventure.starting_page = _fight_page
	_story = auto_free(load("uid://db6oui711vqep").instantiate())  # story.tscn
	_story._reveal_delay = 0.01
	add_child(_story)
	var profile: CharacterProfile = TestCharacters.adventurer()
	assert_bool(profile.is_valid()).is_true()
	_story.start_adventure(adventure, profile)

## Page flips free old UI with queue_free and tweens; let them finish so gdUnit does not report them as orphans
func after_test() -> void:
	await await_millis(500)

func test_fight_page_offers_fight_and_flee() -> void:
	var choices: Array[StoryChoice] = _story._current_story_page.choices
	assert_int(choices.size()).is_equal(2)
	assert_bool(choices[0] is StoryFightDecision and not (choices[0] as StoryFightDecision).fleeing).is_true()
	assert_bool(choices[1] is StoryFightDecision and (choices[1] as StoryFightDecision).fleeing).is_true()
	assert_str(choices[0].get_description()).is_equal("Fight!")
	assert_str(choices[1].get_description()).is_equal("Wun away!")
	assert_object((choices[1] as StoryFightDecision).get_dice_request().attribute).is_same(Rules.AGILITY)

func test_fighting_ends_on_an_outcome_page() -> void:
	var exchanges: int = 0
	while true:
		var choice: StoryFightDecision = _story._current_story_page.choices[0]
		var fight: Fight = choice.fight
		await _pick(choice)
		exchanges += 1
		var page: StoryPage = _story._current_story_page
		if page.is_fight_exchange():
			assert_object(page.fight).is_same(fight)
			assert_bool(fight.is_ongoing()).is_true()
			assert_str(page.page_title).is_equal(fight.get_title())
			assert_int(exchanges).is_less(MAX_EXCHANGES)
			continue
		assert_bool(fight.is_ongoing()).is_false()
		assert_bool(_outcome_pages.has(page.adventure_page)).is_true()
		assert_int(_outcome_pages[page.adventure_page]).is_equal(fight.outcome)
		break
	# Exchange pages are not logged as visits
	assert_int(_story._page_log[_fight_page].size()).is_equal(1)
	assert_int(_story._page_stack.size()).is_equal(1)

func test_fleeing_leaves_after_one_exchange() -> void:
	var choice: StoryFightDecision = _story._current_story_page.choices[1]
	await _pick(choice)
	assert_object(_story._current_story_page.adventure_page).is_same(_outcome_pages.find_key(Fight.Outcome.FLED))
	assert_int(choice.fight.outcome).is_equal(Fight.Outcome.FLED)

func test_resting_is_disabled_while_fighting() -> void:
	var mechanics: Mechanics = _story.get_node("PanelContainer/MarginContainer/HSplitContainer/HBoxContainer/Mechanics")
	assert_bool(mechanics._catch_breath_button.disabled).is_true()
	assert_bool(mechanics._make_camp_button.disabled).is_true()
	# Fleeing ends the fight: the outcome page lets the party rest again
	await _pick(_story._current_story_page.choices[1] as StoryFightDecision)
	assert_bool(_story._current_story_page.is_fighting()).is_false()
	assert_bool(mechanics._make_camp_button.disabled).is_false()
	assert_bool(mechanics._catch_breath_button.disabled).is_equal(not mechanics._party.characters.values().any(func(character: Character) -> bool: return character.can_catch_breath(null)) and not mechanics._can_catch_breath)

func test_monster_lives_in_story() -> void:
	var choice: StoryFightDecision = _story._current_story_page.choices[0]
	assert_object(choice.fight.monster.get_parent()).is_same(_story._monsters)
	assert_object(choice.fight.monster.spawned_from).is_same(_fight_page)

## Releasing the skip key, like a player would, so typed-out text does not slow the test down
func _skip_typing() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = false
	Input.parse_input_event(event)

## Chooses and rolls like the UI does, then waits for the next page
func _pick(choice: StoryFightDecision) -> void:
	var page: StoryPage = _story._current_story_page
	choice.chose()
	choice.roll()
	var waited: int = 0
	while _story._current_story_page == page:
		_skip_typing()
		await await_millis(10)
		waited += 10
		assert_int(waited).is_less(5000)
		if waited >= 5000: return
