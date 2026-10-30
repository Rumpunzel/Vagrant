extends GdUnitTestSuite

## The adventure editor's problem list: what it finds, and where it points.

var _beach: AdventureArea
var _shore: AdventureLocation
var _ruin: AdventureLocation
var _encounters: Array[AdventureEncounter] = [ ]

func before_test() -> void:
	_beach = AdventureArea.new()
	_shore = _location("Shore", _beach)
	_ruin = _location("Ruin", _beach)
	_link(_shore, _ruin)

func test_a_clean_adventure_has_none() -> void:
	assert_array(_texts([ ])).is_empty()

func test_unreachable_locations() -> void:
	var cave: AdventureLocation = _location("Cave", _beach)
	var placed: Array[AdventurePage] = [cave]
	var problems: AdventureProblems = AdventureProblems.new(AdventureGraph.new(_adventure(), placed), [ ] as Array[AdventureEvent])
	assert_array(problems.problems.map(func(problem: AdventureProblems.Problem) -> String: return problem.text)).contains_exactly(["Cave can't be reached from the starting page"])
	assert_object(problems.problems[0].page).is_same(cave)
	assert_object(problems.problems[0].event).is_null()

func test_empty_fights_and_saves_inside_events() -> void:
	var ambush: AdventureEvent = _event("Ambush")
	var fight: AdventureFightDecision = AdventureFightDecision.new()
	fight.description = "Fight!"
	var save: AdventureSaveDecision = AdventureSaveDecision.new()
	save.description = "Hide"
	ambush.decisions = [fight, save] as Array[AdventureDecision]
	TestAdventures.add(_ruin, ambush)
	var problems: Array[AdventureProblems.Problem] = AdventureProblems.new(AdventureGraph.new(_adventure()), [ ] as Array[AdventureEvent]).problems
	assert_array(problems.map(func(problem: AdventureProblems.Problem) -> String: return problem.text)).contains_exactly([
		"Ambush, \"Fight!\": the fight has no monster encounter and no enemies",
		"Ambush, \"Hide\": the save has no attribute",
	])
	assert_object(problems[0].event).is_same(ambush)

func test_missing_files_and_host_links_outside_events() -> void:
	var gone: AdventureDecision = AdventureDecision.new()
	gone.description = "Go on"
	var transition: AdventureTransition = AdventureTransition.new()
	transition._leads_to = "res://nowhere/gone.tres"
	gone.transition = transition
	var home: AdventureDecision = AdventureDecision.new()
	home.description = "Home"
	home.transition = AdventureHostReference.new()
	_ruin.decisions = [gone, home] as Array[AdventureDecision]
	assert_array(_texts([ ])).contains_exactly([
		"Ruin, \"Go on\" leads to a missing file",
		"Ruin, \"Home\": \"Host\" and \"Previous location\" only work inside events",
	])

func test_options_after_one_without_conditions() -> void:
	var always: AdventureEvent = _event("Always")
	var never: AdventureEvent = _event("Never")
	never.conditions = [AdventureIsAlwaysTrueCondition.new()] as Array[AdventureCondition]
	var scenario: AdventureEventScenario = AdventureEventScenario.new()
	scenario.events = [always, never] as Array[AdventureEvent]
	TestAdventures.add(_ruin, scenario)
	assert_array(_texts([ ])).contains_exactly(["Never never shows: Always comes first and has no conditions"])

func test_events_listed_nowhere() -> void:
	var lost: AdventureEvent = _event("Forgotten")
	var heard: AdventureEvent = _event("Heard")
	var source: AdventureEvent = _event("Source")
	var eleanor: AdventureEncounter = AdventureEncounter.new()
	eleanor.events = [heard] as Array[AdventureEvent]
	_encounters = [eleanor] as Array[AdventureEncounter]
	var behind: AdventurePage = AdventurePage.new()
	behind.title = "Behind"
	_link(source, behind)
	TestAdventures.add(_ruin, source)
	assert_array(_texts([lost, heard, source])).contains_exactly(["Forgotten is listed on no location"])

func _texts(event_files: Array[AdventureEvent]) -> Array:
	return AdventureProblems.new(AdventureGraph.new(_adventure()), event_files).problems.map(func(problem: AdventureProblems.Problem) -> String: return problem.text)

func _adventure() -> Adventure:
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = _shore
	adventure.encounters = _encounters
	return adventure

func _location(title: String, area: AdventureArea) -> AdventureLocation:
	var location: AdventureLocation = AdventureLocation.new()
	location.title = title
	location.area = area
	return location

func _event(title: String) -> AdventureEvent:
	var event: AdventureEvent = AdventureEvent.new()
	event.title = title
	return event

func _link(from: AdventurePage, to: AdventurePage) -> void:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.description = "To %s" % to.title
	decision.transition = to
	from.decisions.append(decision)
