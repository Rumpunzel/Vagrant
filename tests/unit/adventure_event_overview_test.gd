extends GdUnitTestSuite

## The adventure editor's overview of one event: an entry per event, a switch per scenario with an entry per option, the same for sub-events, and what they say about themselves.

var _cutthroat: MonsterProfile

func before_test() -> void:
	_cutthroat = TestMonsters.cutthroat()

func test_plain_event_is_one_entry() -> void:
	var ambush: AdventureEvent = _event("Ambush")
	var overview: AdventureEventOverview = AdventureEventOverview.new(ambush)
	assert_int(overview.entries.size()).is_equal(1)
	assert_str(overview.entries[0].label).is_equal("Ambush")
	assert_object(overview.entries[0].parent).is_null()

func test_scenario_is_a_switch_over_its_options() -> void:
	var scenario: AdventureEventScenario = _scenario("Lurker", [_event("Ambush"), _event("Beaten")])
	var overview: AdventureEventOverview = AdventureEventOverview.new(scenario)
	assert_array(overview.entries.map(func(entry: AdventureEventOverview.Entry) -> String: return entry.label)).contains_exactly(["Ambush", "Beaten"])
	assert_int(overview.switches.size()).is_equal(1)
	var switch: AdventureEventOverview.Switch = overview.get_switch(scenario)
	assert_object(switch.outer).is_null()
	for entry: AdventureEventOverview.Entry in overview.entries:
		assert_object(entry.listed_as).is_same(scenario)
		assert_object(entry.switch).is_same(switch)
	assert_object(overview.get_listed_entry(scenario)).is_same(overview.entries[0])

func test_nested_scenarios_are_switches_inside_switches() -> void:
	var inner: AdventureEventScenario = _scenario("Inner", [_event("Deep")])
	var outer: AdventureEventScenario = _scenario("Outer", [inner, _event("Shallow")])
	var overview: AdventureEventOverview = AdventureEventOverview.new(outer)
	assert_object(overview.get_switch(inner).outer).is_same(overview.get_switch(outer))
	assert_object(overview.get_entry(inner.events[0]).switch).is_same(overview.get_switch(inner))

func test_nearby_events_hang_from_their_source() -> void:
	var ambush: AdventureEvent = _event("Ambush")
	var nested: AdventureEvent = _event("Nested")
	ambush.nearby_events.append(nested)
	var overview: AdventureEventOverview = AdventureEventOverview.new(ambush)
	var entry: AdventureEventOverview.Entry = overview.get_entry(nested)
	assert_object(entry.parent).is_same(overview.entries[0])
	assert_object(entry.parent_page).is_same(ambush)

func test_loops_end() -> void:
	var scenario: AdventureEventScenario = _scenario("Loop", [ ])
	scenario.events = [scenario, _event("Only")] as Array[AdventureEvent]
	assert_int(AdventureEventOverview.new(scenario).entries.size()).is_equal(1)

func test_condition_text() -> void:
	var conditions: Array[AdventureCondition] = [_monster_condition(AdventureMonsterCondition.State.DEAD), AdventureIsAlwaysTrueCondition.new(), _monster_condition(AdventureMonsterCondition.State.CAN_FIGHT)]
	assert_str(AdventureEventOverview.get_condition_text(conditions)).is_equal("Cutthroat is dead, Cutthroat can fight")

func test_hiding_text_names_what_is_hidden_at_the_host() -> void:
	var ambush: AdventureEvent = _event("Ambush")
	ambush.exclusivity = 7
	var host: AdventureLocation = AdventureLocation.new()
	host.title = "Ruin"
	var before: AdventureEvent = _event("Birds")
	var scenario: AdventureEventScenario = _scenario("Lurker", [ambush])
	TestAdventures.list(host, [before, scenario] as Array[AdventureEvent])
	var entry: AdventureEventOverview.Entry = AdventureEventOverview.new(scenario).entries[0]
	assert_str(AdventureEventOverview.get_hiding_text(entry, host)).is_equal("Hides Ruin's text and decisions, events before it (Birds), events after it (none)")
	assert_str(AdventureEventOverview.get_hiding_text(entry, null)).is_equal("Hides the host's text and decisions, events before it, events after it")
	ambush.exclusivity = 0
	assert_str(AdventureEventOverview.get_hiding_text(entry, host)).is_empty()

func test_monster_text() -> void:
	var ambush: AdventureEvent = _event("Ambush")
	var entry: AdventureEventOverview.Entry = AdventureEventOverview.new(ambush).entries[0]
	assert_str(AdventureEventOverview.get_monster_text(entry)).is_empty()
	var fight: AdventureFightDecision = AdventureFightDecision.new()
	ambush.decisions.append(fight)
	assert_str(AdventureEventOverview.get_monster_text(entry)).is_equal("Monsters: shared by all hosts")
	ambush.generic = true
	assert_str(AdventureEventOverview.get_monster_text(entry)).is_equal("Monsters: one per host")

func _event(title: String) -> AdventureEvent:
	var event: AdventureEvent = AdventureEvent.new()
	event.title = title
	return event

func _scenario(title: String, options: Array[AdventureEvent]) -> AdventureEventScenario:
	var scenario: AdventureEventScenario = AdventureEventScenario.new()
	scenario.title = title
	scenario.events = options
	return scenario

func _monster_condition(state: AdventureMonsterCondition.State) -> AdventureMonsterCondition:
	var reference: AdventureMonsterReference = AdventureMonsterReference.new()
	reference.monster = _cutthroat
	var condition: AdventureMonsterCondition = AdventureMonsterCondition.new()
	condition.monster = reference
	condition.state = state
	return condition
