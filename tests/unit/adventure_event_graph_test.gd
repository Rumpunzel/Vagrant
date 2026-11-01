extends GdUnitTestSuite

## The adventure editor's view of one event: the pages behind it, its exits and one outlet per decision outcome.

func test_walks_the_pages_behind_the_event() -> void:
	var ambush: AdventureEvent = _page("Ambush")
	var won: AdventureEvent = _page("Won")
	var deeper: AdventureEvent = _page("Deeper")
	_link(ambush, won, "Fight")
	_link(won, deeper, "Go on")
	var graph: AdventureEventGraph = AdventureEventGraph.new(ambush)
	assert_object(graph.event).is_same(ambush)
	assert_array(graph.pages).contains_exactly([ambush, won, deeper])
	assert_array(graph.exits).is_empty()
	assert_int(graph.depths[deeper]).is_equal(2)

func test_locations_are_exits_and_not_walked() -> void:
	var ambush: AdventureEvent = _page("Ambush")
	var temple: AdventureLocation = AdventureLocation.new()
	temple.title = "Temple"
	temple.area = AdventureArea.new()
	_link(ambush, temple, "Leave")
	_link(temple, _page("Beyond"), "Further")
	var graph: AdventureEventGraph = AdventureEventGraph.new(ambush)
	assert_array(graph.pages).contains_exactly([ambush])
	assert_array(graph.exits).contains_exactly([temple])
	assert_int(graph.depths[temple]).is_equal(1)

func test_other_events_are_not_walked() -> void:
	var ambush: AdventureEvent = _page("Ambush")
	var nested: AdventureEvent = _page("Nested")
	_link(nested, _page("Behind"), "Go")
	assert_array(AdventureEventGraph.new(ambush).pages).contains_exactly([ambush])

func test_loops_end() -> void:
	var ambush: AdventureEvent = _page("Ambush")
	var lost: AdventureEvent = _page("Lost")
	_link(ambush, lost, "Fight")
	_link(lost, ambush, "Again")
	assert_array(AdventureEventGraph.new(ambush).pages).contains_exactly([ambush, lost])

func test_fights_and_saves_have_fixed_outcomes() -> void:
	var ambush: AdventureEvent = _page("Ambush")
	var won: AdventureEvent = _page("Won")
	var lost: AdventureEvent = _page("Lost")
	var fight: AdventureFightDecision = AdventureFightDecision.new()
	fight.description = "Fight!\nIt hisses."
	fight.enemies = [TestMonsters.cutthroat()] as Array[MonsterProfile]
	fight.transition = won
	fight.failure_transition = lost
	var beaten: AdventureStageConsequence = AdventureStageConsequence.new()
	beaten.track = "State"
	beaten.stage = "Beaten"
	fight.consequences = [beaten] as Array[AdventureConsequence]
	var sneak: AdventureDecision = AdventureDecision.new()
	sneak.description = "Sneak away"
	ambush.decisions.append(fight)
	ambush.decisions.append(sneak)
	var outlets: Array[AdventureEventGraph.Outlet] = AdventureEventGraph.get_outlets(ambush)
	assert_str(outlets[0].label).is_equal("Fight!")
	assert_bool(outlets[0].to_check).is_true()
	assert_bool(outlets[1].goes_back()).is_true()
	var graph: AdventureEventGraph = AdventureEventGraph.new(ambush)
	# The page's ports: the fight's outcomes, then the choice
	assert_array(AdventureEventGraph.get_ports(ambush).map(func(port: AdventureEventGraph.Outlet) -> String: return port.label)).contains_exactly(["Won", "Lost", "Fled", "Draw", "Sneak away"])
	assert_array(graph.pages).contains_exactly([ambush, won, lost])
	assert_int(graph.depths[won]).is_equal(1)
	assert_str(AdventureEventGraph.describe_check(fight)).is_equal("Fight: Cutthroat")
	var outcomes: Array[AdventureEventGraph.Outlet] = AdventureEventGraph.get_outcomes(fight)
	assert_array(outcomes.map(func(outcome: AdventureEventGraph.Outlet) -> String: return outcome.label)).contains_exactly(["Won", "Lost", "Fled", "Draw"])
	assert_object(outcomes[0].target).is_same(won)
	assert_str(AdventureEventGraph.describe_consequences(outcomes[0].consequences)).is_equal("its own → Beaten")
	# No flee transition: going back
	assert_bool(outcomes[2].goes_back()).is_true()

func test_save_outcomes() -> void:
	var save: AdventureSaveDecision = AdventureSaveDecision.new()
	save.attribute = Rules.AGILITY
	save.difficulty = 7
	save.failure_consequences = [AdventureInjuryConsequence.new()] as Array[AdventureConsequence]
	var outcomes: Array[AdventureEventGraph.Outlet] = AdventureEventGraph.get_outcomes(save)
	assert_array(outcomes.map(func(outcome: AdventureEventGraph.Outlet) -> String: return outcome.label)).contains_exactly(["Success", "Failure"])
	assert_str(AdventureEventGraph.describe_check(save)).is_equal("Save: %s 7" % Rules.AGILITY.descriptor)
	assert_str(AdventureEventGraph.describe_consequences(outcomes[1].consequences)).is_equal("Injury (margin as damage)")

func test_host_reference_is_an_outlet_to_the_host() -> void:
	var ambush: AdventureEvent = _page("Ambush")
	var decision: AdventureDecision = AdventureDecision.new()
	decision.description = "Fight"
	decision.transition = AdventureHostReference.new()
	ambush.decisions.append(decision)
	var graph: AdventureEventGraph = AdventureEventGraph.new(ambush)
	assert_bool(graph.leads_to_host).is_true()
	var outlet: AdventureEventGraph.Outlet = AdventureEventGraph.get_outlets(ambush)[0]
	assert_str(outlet.label).is_equal("Fight")
	assert_bool(outlet.to_host).is_true()
	assert_object(outlet.target).is_null()
	assert_array(graph.pages).contains_exactly([ambush])

func test_condition_text() -> void:
	var conditions: Array[AdventureCondition] = [_stage_condition("Dead"), AdventureIsAlwaysTrueCondition.new(), _stage_condition("Lurking")]
	assert_str(AdventureEventGraph.describe_conditions(conditions)).is_equal("its own: State is Dead, its own: State is Lurking")

func test_hiding_text_goes_by_the_location_s_order() -> void:
	var ambush: AdventureEvent = _page("Ambush")
	ambush.exclusivity = 7
	var host: AdventureLocation = AdventureLocation.new()
	host.title = "Ruin"
	TestAdventures.list(host, [_page("Birds"), ambush] as Array[AdventureEvent])
	var none: Array[AdventureEncounter] = [ ]
	assert_str(AdventureEventGraph.describe_hiding(ambush, host, none)).is_equal("Hides Ruin's text and decisions, events before it (Birds), events after it (none)")
	assert_str(AdventureEventGraph.describe_hiding(ambush, null, none)).is_equal("Hides the host's text and decisions, events before it, events after it")
	# An encounter's events count where the location's order puts them: after its own events unless listed first
	var eleanor: AdventureEncounter = AdventureEncounter.new()
	eleanor.events = [_page("Knocking")] as Array[AdventureEvent]
	var encounters: Array[AdventureEncounter] = [eleanor]
	assert_str(AdventureEventGraph.describe_hiding(ambush, host, encounters)).is_equal("Hides Ruin's text and decisions, events before it (Birds), events after it (Knocking)")
	ambush.exclusivity = 0
	assert_str(AdventureEventGraph.describe_hiding(ambush, host, none)).is_empty()

func _stage_condition(stage: String) -> AdventureStageCondition:
	var condition: AdventureStageCondition = AdventureStageCondition.new()
	condition.track = "State"
	condition.stages = [stage] as Array[String]
	return condition

func _page(title: String) -> AdventureEvent:
	var page: AdventureEvent = AdventureEvent.new()
	page.title = title
	return page

func _link(from: AdventurePage, to: AdventurePage, description: String) -> void:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.description = description
	decision.transition = to
	from.decisions.append(decision)
