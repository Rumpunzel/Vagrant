extends GdUnitTestSuite

## The adventure editor's overview of one plain event: its entry, and what it says about itself.

func test_plain_event_is_one_entry() -> void:
	var ambush: AdventureEvent = _event("Ambush")
	var overview: AdventureEventOverview = AdventureEventOverview.new(ambush)
	assert_int(overview.entries.size()).is_equal(1)
	assert_str(overview.entries[0].label).is_equal("Ambush")

func test_scenarios_have_no_overview() -> void:
	var scenario: AdventureEventScenario = _scenario("Lurker", [_event("Ambush")] as Array[AdventureEvent])
	assert_array(AdventureEventOverview.new(scenario).entries).is_empty()

func test_near_events_say_so() -> void:
	var hearing: AdventureEvent = _event("Hearing")
	hearing.where = AdventureEvent.Where.NEAR
	var entry: AdventureEventOverview.Entry = AdventureEventOverview.new(hearing).entries[0]
	assert_str(entry.label).is_equal("Hearing (near)")
	assert_bool(entry.is_nearby).is_true()

func test_condition_text() -> void:
	var conditions: Array[AdventureCondition] = [_stage_condition("Dead"), AdventureIsAlwaysTrueCondition.new(), _stage_condition("Lurking")]
	assert_str(AdventureEventOverview.get_condition_text(conditions)).is_equal("its own: State is Dead, its own: State is Lurking")

func test_hiding_text_names_what_is_hidden_at_the_host() -> void:
	var ambush: AdventureEvent = _event("Ambush")
	ambush.exclusivity = 7
	var host: AdventureLocation = AdventureLocation.new()
	host.title = "Ruin"
	TestAdventures.list(host, [_event("Birds"), ambush] as Array[AdventureEvent])
	var entry: AdventureEventOverview.Entry = AdventureEventOverview.new(ambush).entries[0]
	assert_str(AdventureEventOverview.get_hiding_text(entry, host)).is_equal("Hides Ruin's text and decisions, events before it (Birds), events after it (none)")
	assert_str(AdventureEventOverview.get_hiding_text(entry, null)).is_equal("Hides the host's text and decisions, events before it, events after it")
	ambush.exclusivity = 0
	assert_str(AdventureEventOverview.get_hiding_text(entry, host)).is_empty()

func _event(title: String) -> AdventureEvent:
	var event: AdventureEvent = AdventureEvent.new()
	event.title = title
	return event

func _scenario(title: String, options: Array[AdventureEvent]) -> AdventureEventScenario:
	var scenario: AdventureEventScenario = AdventureEventScenario.new()
	scenario.title = title
	scenario.events = options
	return scenario

func _stage_condition(stage: String) -> AdventureStageCondition:
	var condition: AdventureStageCondition = AdventureStageCondition.new()
	condition.track = "State"
	condition.stages = [stage] as Array[String]
	return condition
