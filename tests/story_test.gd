extends GdUnitTestSuite

## Story bookkeeping with plain decisions: transitions, going back, visit and decision logs.

const DORIAN: String = "uid://73nsysikxf7j"  # dorian.tres
const STORY: String = "uid://db6oui711vqep"  # story.tscn

var _story: Story
var _start: AdventurePage
var _next: AdventurePage
var _to_next: AdventureDecision
var _back: AdventureDecision

func before_test() -> void:
	_start = _page("Start")
	_next = _page("Next")
	_to_next = _decision("Go on", _next)
	_start._decisions = [_to_next] as Array[AdventureDecision]
	# No transition: back to the previous page
	_back = _decision("Go back", null)
	_next._decisions = [_back] as Array[AdventureDecision]
	var adventure: Adventure = Adventure.new()
	adventure.title = "Test"
	adventure.starting_page = _start
	_story = auto_free(load(STORY).instantiate())
	_story._reveal_delay = 0.01
	add_child(_story)
	_story.start_adventure(adventure, (load(DORIAN) as CharacterProfile).duplicate(true))

func after_test() -> void:
	await await_millis(500)

func test_starts_on_starting_page() -> void:
	assert_object(_story._current_story_page.adventure_page).is_same(_start)
	assert_int(_story.get_how_often_page_has_been_entered(_start)).is_equal(1)
	assert_object(_story._protagonist).is_not_null()

func test_decision_leads_to_transition() -> void:
	await _choose(0)
	assert_object(_story._current_story_page.adventure_page).is_same(_next)
	assert_int(_story.get_how_often_decision_has_been_made(_to_next)).is_equal(1)
	assert_int(_story.get_how_often_page_has_been_entered(_next)).is_equal(1)

func test_decision_without_transition_goes_back() -> void:
	await _choose(0)
	await _choose(0)
	assert_object(_story._current_story_page.adventure_page).is_same(_start)
	assert_int(_story.get_how_often_page_has_been_entered(_start)).is_equal(2)

func test_dead_end_offers_turn_back() -> void:
	_next._decisions = [] as Array[AdventureDecision]
	await _choose(0)
	var choices: Array[StoryChoice] = _story._current_story_page.choices
	assert_int(choices.size()).is_equal(1)
	assert_object(choices[0].get_adventure_decision()).is_same(AdventureDecision.get_turn_back())
	assert_str(choices[0].get_description()).is_equal("Turn back.")
	await _choose(0)
	assert_object(_story._current_story_page.adventure_page).is_same(_start)
	# Turning back is not logged as a decision
	assert_int(_story.get_how_often_decision_has_been_made(AdventureDecision.get_turn_back())).is_equal(0)

func test_consequences_resolve() -> void:
	var injury: AdventureInjuryConsequence = AdventureInjuryConsequence.new()
	_to_next.consequences = [injury] as Array[AdventureConsequence]
	var injuries: Array[Injury] = []
	_story._protagonist.suffered_injury.connect(func(suffered: Injury) -> void: injuries.append(suffered))
	await _choose(0)
	# Plain decisions resolve consequences with no margin, so the injury consequence does nothing
	assert_array(injuries).is_empty()
	assert_object(_story._current_story_page.adventure_page).is_same(_next)

func _choose(index: int) -> void:
	var page: StoryPage = _story._current_story_page
	page.choices[index].chose()
	var waited: int = 0
	while _story._current_story_page == page and waited < 5000:
		await await_millis(10)
		waited += 10

func _page(title: String) -> AdventurePage:
	var page: AdventurePage = AdventurePage.new()
	page._title = title
	return page

func _decision(description: String, transition: AdventurePage) -> AdventureDecision:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.description = description
	decision.transition = transition
	return decision
