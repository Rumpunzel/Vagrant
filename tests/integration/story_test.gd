extends GdUnitTestSuite

## Story bookkeeping with plain decisions: transitions, going back, visit and decision logs, event hosts.

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

func test_monster_condition_follows_the_monster() -> void:
	var reference: AdventureMonsterReference = AdventureMonsterReference.new()
	reference.monster = TestMonsters.cutthroat()
	var can_fight: AdventureMonsterCondition = _monster_condition(reference, AdventureMonsterCondition.State.CAN_FIGHT)
	var beaten: AdventureMonsterCondition = _monster_condition(reference, AdventureMonsterCondition.State.INCAPACITATED)
	var dead: AdventureMonsterCondition = _monster_condition(reference, AdventureMonsterCondition.State.DEAD)
	assert_array([can_fight.is_true(_story, _start), beaten.is_true(_story, _start), dead.is_true(_story, _start)]).is_equal([true, false, false])
	reference.get_monster(_story, _start).incapacitated = true
	assert_array([can_fight.is_true(_story, _start), beaten.is_true(_story, _start), dead.is_true(_story, _start)]).is_equal([false, true, false])
	# Another page's monster of the same profile is a different one
	assert_bool(can_fight.is_true(_story, _next)).is_true()

func test_killing_a_monster() -> void:
	var reference: AdventureMonsterReference = AdventureMonsterReference.new()
	reference.monster = TestMonsters.cutthroat()
	reference.spawned_by = _start
	var kill: AdventureKillMonsterConsequence = AdventureKillMonsterConsequence.new()
	kill.monster = reference
	kill.resolve(_story, 0)
	var monster: Monster = _story.get_monster(_start, reference.monster)
	assert_bool(monster.dead).is_true()
	assert_bool(monster.can_fight()).is_false()
	# Referenced from another page, it is still the start page's monster
	assert_bool(_monster_condition(reference, AdventureMonsterCondition.State.DEAD).is_true(_story, _next)).is_true()

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

func test_consequences_resolve() -> void:
	var injury: AdventureInjuryConsequence = AdventureInjuryConsequence.new()
	_to_next.consequences = [injury] as Array[AdventureConsequence]
	var injuries: Array[Injury] = []
	_story._protagonist.suffered_injury.connect(func(suffered: Injury) -> void: injuries.append(suffered))
	await _choose(0)
	# Plain decisions resolve consequences with no margin, so the injury consequence does nothing
	assert_array(injuries).is_empty()
	assert_object(_story._current_story_page.adventure_page).is_same(_next)

func test_host_reference_returns_to_the_page_the_event_was_on() -> void:
	var event: AdventurePage = _page("")
	var inside: AdventurePage = _page("Inside")
	event.decisions = [_decision("Look closer", inside)] as Array[AdventureDecision]
	var back_to_host: AdventureDecision = _decision("Return", null)
	back_to_host.transition = AdventureHostReference.new()
	inside.decisions = [back_to_host] as Array[AdventureDecision]
	_start.events = [event] as Array[AdventurePage]
	_story.enter_page(_start)
	# The event's decisions come first
	await _choose(0)
	assert_object(_story._current_story_page.adventure_page).is_same(inside)
	assert_object(_story.get_host()).is_same(_start)
	await _choose(0)
	assert_object(_story._current_story_page.adventure_page).is_same(_start)

func test_previous_location_is_the_page_before_the_host() -> void:
	var event: AdventurePage = _page("")
	var inside: AdventurePage = _page("Inside")
	var deeper: AdventurePage = _page("Deeper")
	event.decisions = [_decision("Fight", inside)] as Array[AdventureDecision]
	inside.decisions = [_decision("Run", deeper)] as Array[AdventureDecision]
	var flee: AdventureDecision = _decision("Away", null)
	flee.transition = AdventurePreviousLocationReference.new()
	deeper.decisions = [flee] as Array[AdventureDecision]
	_next.events = [event] as Array[AdventurePage]
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

func test_generic_events_spawn_per_host() -> void:
	var event: AdventurePage = _page("Ambush")
	var cutthroat: MonsterProfile = TestMonsters.cutthroat()
	_story._host = _start
	var at_start: Monster = _story.get_monster(event, cutthroat)
	_story._host = _next
	# Shared by default: one monster wherever the event is
	assert_object(_story.get_monster(event, cutthroat)).is_same(at_start)
	event.generic = true
	var at_next: Monster = _story.get_monster(event, cutthroat)
	assert_object(at_next).is_not_same(at_start)
	_story._host = _start
	assert_object(_story.get_monster(event, cutthroat)).is_not_same(at_next)

func _choose(index: int) -> void:
	var page: StoryPage = _story._current_story_page
	page.choices[index].chose()
	var waited: int = 0
	while _story._current_story_page == page and waited < 5000:
		await await_millis(10)
		waited += 10

func _page(title: String) -> AdventurePage:
	var page: AdventurePage = AdventurePage.new()
	page.title = title
	return page

func _decision(description: String, transition: AdventurePage) -> AdventureDecision:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.description = description
	decision.transition = transition
	return decision

func _monster_condition(reference: AdventureMonsterReference, state: AdventureMonsterCondition.State) -> AdventureMonsterCondition:
	var condition: AdventureMonsterCondition = AdventureMonsterCondition.new()
	condition.monster = reference
	condition.state = state
	return condition
