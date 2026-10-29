@tool
class_name AdventureProblems
extends RefCounted

## Mistakes in an adventure the editor can see before playing it: fights without enemies, saves without attribute, links to missing files,
## locations nobody reaches, events listed nowhere, scenario options that can never show, host links outside events

class Problem:
	var text: String
	## The page to show (the one holding the decision)
	var page: AdventurePage
	## The event to open it in; none: on the map
	var event: AdventurePage

	func _init(problem_text: String, problem_page: AdventurePage, problem_event: AdventurePage) -> void:
		text = problem_text
		page = problem_page
		event = problem_event

var problems: Array[Problem] = [ ]

var _checked: Array[AdventureDecision] = [ ]

## [param event_files]: every event there is, to find those listed nowhere
func _init(graph: AdventureGraph, event_files: Array[AdventurePage]) -> void:
	for page: AdventurePage in graph.unreachable: _add("%s can't be reached from the starting page" % AdventureGraph.get_title(page), page, null)
	for page: AdventurePage in graph.pages: _check_decisions(page, null)
	var events: Array[AdventurePage] = [ ]
	events.assign(graph.event_hosts.keys())
	var index: int = 0
	while index < events.size():
		for nearby: AdventurePage in events[index].nearby_events: if nearby != null and not events.has(nearby): events.append(nearby)
		index += 1
	# Pages behind events often sit in the events folders too; they are reached, not listed
	var reached: Array[AdventurePage] = events.duplicate()
	for event: AdventurePage in events:
		if event is AdventureEventScenario:
			_check_options(event as AdventureEventScenario)
			continue
		for page: AdventurePage in AdventureEventGraph.new(event).pages:
			_check_decisions(page, event)
			if not reached.has(page): reached.append(page)
	for event: AdventurePage in event_files:
		if not reached.has(event): _add("%s is listed on no location" % AdventureGraph.get_title(event), event, event)

func _check_decisions(page: AdventurePage, event: AdventurePage) -> void:
	for decision: AdventureDecision in page.decisions:
		if decision == null or _checked.has(decision): continue
		_checked.append(decision)
		var where: String = "%s, \"%s\"" % [AdventureGraph.get_title(page), decision.description.get_slice("\n", 0)]
		if decision is AdventureFightDecision and (decision.get(&"enemies") as Array).is_empty(): _add("%s: the fight has no enemies" % where, page, event)
		if decision is AdventureSaveDecision and decision.get(&"attribute") == null: _add("%s: the save has no attribute" % where, page, event)
		for reference: AdventurePageReference in AdventureGraph.get_references(decision).values():
			if reference is AdventureTransition and (reference as AdventureTransition).leads_nowhere(): _add("%s leads to a missing file" % where, page, event)
			if event == null and (reference is AdventureHostReference or reference is AdventurePreviousLocationReference):
				_add("%s: \"Host\" and \"Previous location\" only work inside events" % where, page, event)

## An option without conditions always fits, so the ones after it never show
func _check_options(scenario: AdventureEventScenario) -> void:
	for index: int in scenario.events.size() - 1:
		var option: AdventurePage = scenario.events[index]
		if option == null or not option.conditions.is_empty(): continue
		for later: AdventurePage in scenario.events.slice(index + 1):
			if later != null: _add("%s never shows: %s comes first and has no conditions" % [AdventureGraph.get_title(later), AdventureGraph.get_title(option)], later, scenario)
		return

func _add(text: String, page: AdventurePage, event: AdventurePage) -> void:
	problems.append(Problem.new(text, page, event))
