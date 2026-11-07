extends GdUnitTestSuite

## Story bookkeeping with plain decisions: transitions, going back, visit and decision logs, event hosts.

const STORY: String = "uid://db6oui711vqep"  # story.tscn

var _story: Story
var _start: AdventureLocation
var _next: AdventureLocation
var _to_next: AdventureDecision
var _back: AdventureDecision

func before_test() -> void:
	_start = _location("Start")
	_next = _location("Next")
	_to_next = _decision("Go on", _next)
	_start.decisions = [_to_next] as Array[AdventureDecision]
	# No transition: back to the previous page
	_back = _decision("Go back", null)
	_next.decisions = [_back] as Array[AdventureDecision]
	var adventure: Adventure = Adventure.new()
	adventure.title = "Test"
	adventure.starting_page = _start
	_story = auto_free(load(STORY).instantiate())
	_story._reveal_delay = 0.01
	add_child(_story)
	_story.start_adventure(adventure, TestCharacters.adventurer())

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

func test_decision_can_go_back_several_pages() -> void:
	var last: AdventurePage = _page("Last")
	var back_twice: AdventureDecision = _decision("Back twice", null)
	back_twice.back_steps = 2
	last.decisions = [back_twice] as Array[AdventureDecision]
	_next.decisions = [_decision("Go on", last)] as Array[AdventureDecision]
	await _choose(0)
	await _choose(0)
	await _choose(0)
	assert_object(_story._current_story_page.adventure_page).is_same(_start)

func test_dead_end_offers_turn_back() -> void:
	_next.decisions = [] as Array[AdventureDecision]
	await _choose(0)
	var choices: Array[StoryChoice] = _story._current_story_page.choices
	assert_int(choices.size()).is_equal(1)
	assert_object(choices[0].get_adventure_decision()).is_same(AdventureDecision.get_turn_back())
	assert_str(choices[0].get_description()).is_equal("Turn back.")
	await _choose(0)
	assert_object(_story._current_story_page.adventure_page).is_same(_start)
	# Turning back is not logged as a decision
	assert_int(_story.get_how_often_decision_has_been_made(AdventureDecision.get_turn_back())).is_equal(0)

func test_going_back_twice_goes_back_further() -> void:
	# Start → Next → Detail, back to Next, back again: to Start, not to Detail
	var detail: AdventurePage = AdventurePage.new()
	detail.title = "Detail"
	_next.decisions = [_decision("Look", detail), _back] as Array[AdventureDecision]
	await _choose(0)
	await _choose(0)
	await _choose(0)
	assert_object(_story._current_story_page.adventure_page).is_same(_next)
	await _choose(1)
	assert_object(_story._current_story_page.adventure_page).is_same(_start)
	assert_array(_story._page_stack).is_empty()

func test_consequences_resolve() -> void:
	var injury: AdventureInjuryConsequence = AdventureInjuryConsequence.new()
	_to_next.consequences = [injury] as Array[AdventureConsequence]
	var injuries: Array[Injury] = []
	_story._protagonist.suffered_injury.connect(func(suffered: Injury) -> void: injuries.append(suffered))
	await _choose(0)
	# Plain decisions resolve consequences with no margin, so the injury consequence does nothing
	assert_array(injuries).is_empty()
	assert_object(_story._current_story_page.adventure_page).is_same(_next)

func test_what_is_gained_and_lost_is_told_on_the_next_page() -> void:
	var rations: ItemProfile = ItemProfile.create_item("Rations")
	var gain_sword: AdventureGainConsequence = AdventureGainConsequence.new()
	gain_sword.item = WeaponProfile.create("Sword", Rules.d10)
	var gain_rations: AdventureGainConsequence = AdventureGainConsequence.new()
	gain_rations.item = rations
	gain_rations.count = 2
	_to_next.consequences = [gain_sword, gain_rations] as Array[AdventureConsequence]
	_next.description = "The road goes on."
	await _choose(0)
	assert_str(_story._current_story_page.description).is_equal("[p][i]You gain the Sword and 2 Rations.[/i][/p][p]The road goes on.[/p]")
	# Told once
	var lose: AdventureLoseConsequence = AdventureLoseConsequence.new()
	lose.item = rations
	_back.consequences = [lose] as Array[AdventureConsequence]
	await _choose(0)
	assert_str(_story._current_story_page.description).starts_with("[p][i]You lose the Rations.[/i][/p]")

func test_only_effects_that_show_right_away_are_paused_for() -> void:
	_story._reveal_delay = 3.0
	var gain: AdventureGainConsequence = AdventureGainConsequence.new()
	gain.item = ItemProfile.create_item("Rations")
	_to_next.consequences = [gain] as Array[AdventureConsequence]
	var started: int = Time.get_ticks_msec()
	await _choose(0)
	# Gaining is told on the next page: no pause
	assert_object(_story._current_story_page.adventure_page).is_same(_next)
	assert_int(Time.get_ticks_msec() - started).is_less(1500)
	assert_bool(AdventureInjuryConsequence.new().is_shown()).is_true()

func test_host_reference_returns_to_the_page_the_event_was_on() -> void:
	var event: AdventureEvent = _page("")
	var inside: AdventurePage = _page("Inside")
	event.decisions = [_decision("Look closer", inside)] as Array[AdventureDecision]
	var back_to_host: AdventureDecision = _decision("Return", null)
	back_to_host.transition = AdventureHostReference.new()
	inside.decisions = [back_to_host] as Array[AdventureDecision]
	TestAdventures.list(_start, [event] as Array[AdventureEvent])
	_story.enter_page(_start)
	# The event's decisions come first
	await _choose(0)
	assert_object(_story._current_story_page.adventure_page).is_same(inside)
	assert_object(_story.get_host()).is_same(_start)
	await _choose(0)
	assert_object(_story._current_story_page.adventure_page).is_same(_start)

func test_previous_location_is_the_page_before_the_host() -> void:
	var event: AdventureEvent = _page("")
	var inside: AdventurePage = _page("Inside")
	var deeper: AdventurePage = _page("Deeper")
	event.decisions = [_decision("Fight", inside)] as Array[AdventureDecision]
	inside.decisions = [_decision("Run", deeper)] as Array[AdventureDecision]
	var flee: AdventureDecision = _decision("Away", null)
	flee.transition = AdventurePreviousLocationReference.new()
	deeper.decisions = [flee] as Array[AdventureDecision]
	TestAdventures.list(_next, [event] as Array[AdventureEvent])
	await _choose(0)
	# On the host: the event's decision first
	await _choose(0)
	await _choose(0)
	assert_object(_story._current_story_page.adventure_page).is_same(deeper)
	await _choose(0)
	assert_object(_story._current_story_page.adventure_page).is_same(_start)

func test_starts_behind_an_event_on_its_host() -> void:
	var inside: AdventurePage = _page("Inside")
	var back_to_host: AdventureDecision = _decision("Return", null)
	back_to_host.transition = AdventureHostReference.new()
	inside.decisions = [back_to_host] as Array[AdventureDecision]
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = _start
	# A story of its own: the one of before_test has started already
	_story = auto_free(load(STORY).instantiate())
	_story._reveal_delay = 0.01
	add_child(_story)
	_story.start_adventure(adventure, TestCharacters.adventurer(), inside, _next)
	assert_object(_story._current_story_page.adventure_page).is_same(inside)
	assert_object(_story.get_host()).is_same(_next)
	await _choose(0)
	assert_object(_story._current_story_page.adventure_page).is_same(_next)

func test_encounters_keep_their_monster_one_off_fights_get_one_per_location() -> void:
	var cutthroat: MonsterProfile = TestMonsters.cutthroat()
	var encounter: AdventureEncounter = AdventureEncounter.new()
	var event: AdventureEvent = _page("Ambush")
	_story._location = _start
	var encounter_at_start: Monster = _story.get_monster(encounter, cutthroat)
	var one_off_at_start: Monster = _story.get_monster(event, cutthroat)
	_story._location = _next
	assert_object(_story.get_monster(encounter, cutthroat)).is_same(encounter_at_start)
	var one_off_at_next: Monster = _story.get_monster(event, cutthroat)
	assert_object(one_off_at_next).is_not_same(one_off_at_start)
	_story._location = _start
	assert_object(_story.get_monster(event, cutthroat)).is_same(one_off_at_start)

func _choose(index: int) -> void:
	var page: StoryPage = _story._current_story_page
	page.choices[index].chose()
	var waited: int = 0
	while _story._current_story_page == page and waited < 5000:
		await await_millis(10)
		waited += 10

func _location(title: String) -> AdventureLocation:
	var location: AdventureLocation = AdventureLocation.new()
	location.title = title
	return location

## An event, also usable as a plain page
func _page(title: String) -> AdventureEvent:
	var page: AdventureEvent = AdventureEvent.new()
	page.title = title
	return page

func _decision(description: String, transition: AdventurePage) -> AdventureDecision:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.description = description
	decision.transition = transition
	return decision
