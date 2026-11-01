@tool
class_name AdventureProblems
extends RefCounted

## Mistakes in an adventure the editor can see before playing it: fights without enemies, saves without attribute, links to missing files,
## locations nobody reaches, events listed nowhere, scenario options that can never show, host links outside events, and events whose
## conditions nothing can make true (a stage nothing sets, a monster nothing fights or kills). It only knows what the content does, not chance.

class Problem:
	var text: String
	## The page to show (the one holding the decision)
	var page: AdventurePage
	## The event to open it in; none: on the map
	var event: AdventureEvent

	func _init(problem_text: String, problem_page: AdventurePage, problem_event: AdventurePage) -> void:
		text = problem_text
		page = problem_page
		event = problem_event

var problems: Array[Problem] = [ ]

var _checked: Array[AdventureDecision] = [ ]
## { subject -> { track -> Array[String] } }: the stages something in the adventure sets
var _set_stages: Dictionary[Resource, Dictionary] = {}
## Encounters whose monster something fights, kills
var _fought: Array[AdventureEncounter] = [ ]
var _killed: Array[AdventureEncounter] = [ ]
var _graph: AdventureGraph

## [param event_files]: every event there is, to find those listed nowhere
func _init(graph: AdventureGraph, event_files: Array[AdventureEvent]) -> void:
	_graph = graph
	for page: AdventurePage in graph.unreachable: _add("%s can't be reached from the starting page" % AdventureGraph.get_title(page), page, null)
	for page: AdventurePage in graph.pages: _check_decisions(page, null)
	var events: Array[AdventureEvent] = [ ]
	events.assign(graph.event_hosts.keys())
	# Events listed only on pages behind other events are reached, not listed on a location
	var reached: Array[AdventurePage] = [ ]
	reached.assign(events)
	for event: AdventureEvent in events:
		if event is AdventureEventScenario:
			_check_options(event as AdventureEventScenario)
			continue
		for page: AdventurePage in AdventureEventGraph.new(event).pages:
			_check_decisions(page, event)
			if not reached.has(page): reached.append(page)
	for event: AdventureEvent in event_files:
		if not reached.has(event): _add("%s is listed on no location" % AdventureGraph.get_title(event), event, event)
	_find_what_happens(events)
	for event: AdventureEvent in events: _check_conditions(event)

## What the decisions of locations and events do to stages and monsters
func _find_what_happens(events: Array[AdventureEvent]) -> void:
	for page: AdventurePage in _graph.pages:
		if page is AdventureLocation: _note_decisions(page, [page] as Array[Resource], null)
	for event: AdventureEvent in events:
		var encounter: AdventureEncounter = _graph.get_encounter_of(event)
		for page: AdventurePage in AdventureEventGraph.new(event).pages: _note_decisions(page, _get_own_subjects(event), encounter)

## What an empty subject means in [param event]: its encounter, else the locations it is on
func _get_own_subjects(event: AdventureEvent) -> Array[Resource]:
	var subjects: Array[Resource] = [ ]
	var encounter: AdventureEncounter = _graph.get_encounter_of(event)
	if encounter != null: subjects.append(encounter)
	else: subjects.append_array(_graph.get_location_hosts(event))
	return subjects

func _note_decisions(page: AdventurePage, own: Array[Resource], encounter: AdventureEncounter) -> void:
	for decision: AdventureDecision in page.decisions:
		if decision == null: continue
		var fight: AdventureFightDecision = decision as AdventureFightDecision
		if fight != null and fight.enemies.is_empty(): _note_encounter(_fought, fight.encounter, encounter)
		for outcome: AdventureDecision.Outcome in decision.get_outcomes():
			for consequence: AdventureConsequence in decision.get_consequences_of(outcome):
				if consequence is AdventureKillConsequence: _note_encounter(_killed, (consequence as AdventureKillConsequence).encounter, encounter)
				var stage: AdventureStageConsequence = consequence as AdventureStageConsequence
				if stage == null: continue
				for subject: Resource in _resolve(stage.subject, own):
					var stages: Array = (_set_stages.get_or_add(subject, {}) as Dictionary).get_or_add(stage.track, [ ])
					if not stages.has(stage.stage): stages.append(stage.stage)

func _note_encounter(into: Array[AdventureEncounter], path: String, own: AdventureEncounter) -> void:
	var encounter: AdventureEncounter = Files.load_existing(path) as AdventureEncounter if not path.is_empty() else own
	if encounter != null and not into.has(encounter): into.append(encounter)

static func _resolve(path: String, own: Array[Resource]) -> Array[Resource]:
	if path.is_empty(): return own
	var subjects: Array[Resource] = [ ]
	var subject: Resource = Files.load_existing(path)
	if subject != null: subjects.append(subject)
	return subjects

## Stage conditions nothing can make true (none of the stages is a track's first or set anywhere), body conditions nothing brings about
func _check_conditions(event: AdventureEvent) -> void:
	var title: String = AdventureGraph.get_title(event)
	for condition: AdventureCondition in event.conditions:
		var stage: AdventureStageCondition = condition as AdventureStageCondition
		var body: AdventureMonsterCondition = condition as AdventureMonsterCondition
		if stage != null:
			var subjects: Array[Resource] = _resolve(stage.subject, _get_own_subjects(event))
			if not subjects.is_empty() and not subjects.any(_can_reach.bind(stage)):
				_add("%s never shows: it needs %s %s, which is no track's start and nothing sets" % [title, stage.track, " or ".join(stage.stages)], event, event)
		elif body != null:
			var encounter: AdventureEncounter = Files.load_existing(body.encounter) as AdventureEncounter if not body.encounter.is_empty() else _graph.get_encounter_of(event)
			if encounter == null: continue
			var whose: String = AdventureGraph.get_title(encounter)
			if not encounter.profile is MonsterProfile: _add("%s: %s has no monster to be %s" % [title, whose, AdventureMonsterCondition.STATE_TEXTS[body.state].trim_prefix("is ")], event, event)
			elif body.state == AdventureMonsterCondition.State.BEATEN and not _fought.has(encounter): _add("%s never shows: nothing fights %s" % [title, whose], event, event)
			elif body.state == AdventureMonsterCondition.State.DEAD and not _killed.has(encounter): _add("%s never shows: nothing kills %s" % [title, whose], event, event)

## Whether [param subject] can be in one of the stages [param condition] needs: one is its track's first, or something sets it
func _can_reach(subject: Resource, condition: AdventureStageCondition) -> bool:
	var track: AdventureStageTrack = AdventureStageTrack.find(AdventureStageTrack.get_tracks_of(subject), condition.track)
	if track != null and not track.stages.is_empty() and condition.stages.has(track.stages[0]): return true
	var set_stages: Array = (_set_stages.get(subject, {}) as Dictionary).get(condition.track, [ ])
	return condition.stages.any(func(stage: String) -> bool: return set_stages.has(stage))

func _check_decisions(page: AdventurePage, event: AdventureEvent) -> void:
	for decision: AdventureDecision in page.decisions:
		if decision == null or _checked.has(decision): continue
		_checked.append(decision)
		var where: String = "%s, \"%s\"" % [AdventureGraph.get_title(page), decision.description.get_slice("\n", 0)]
		if decision is AdventureFightDecision and not _has_monster(decision as AdventureFightDecision, event): _add("%s: the fight has no monster encounter and no enemies" % where, page, event)
		if decision is AdventureSaveDecision and (decision as AdventureSaveDecision).attribute == null: _add("%s: the save has no attribute" % where, page, event)
		for link: AdventurePageReference in decision.get_page_references():
			if link is AdventureTransition and (link as AdventureTransition).leads_nowhere(): _add("%s leads to a missing file" % where, page, event)
			if event == null and (link is AdventureHostReference or link is AdventurePreviousLocationReference):
				_add("%s: \"Host\" and \"Previous location\" only work inside events" % where, page, event)

## An option without conditions always fits, so the ones after it never show
func _check_options(scenario: AdventureEventScenario) -> void:
	if scenario.pick != AdventureEventScenario.Pick.FIRST: return
	for index: int in scenario.events.size() - 1:
		var option: AdventureEvent = scenario.events[index]
		if option == null or not option.conditions.is_empty(): continue
		for later: AdventureEvent in scenario.events.slice(index + 1):
			if later != null: _add("%s never shows: %s comes first and has no conditions" % [AdventureGraph.get_title(later), AdventureGraph.get_title(option)], later, scenario)
		return

## A named encounter, enemies, or an event of an encounter with a monster
func _has_monster(fight: AdventureFightDecision, event: AdventureEvent) -> bool:
	if not fight.encounter.is_empty() or not fight.enemies.is_empty(): return true
	var encounter: AdventureEncounter = _graph.get_encounter_of(event) if event != null else null
	return encounter != null and encounter.profile is MonsterProfile

func _add(text: String, page: AdventurePage, event: AdventureEvent) -> void:
	problems.append(Problem.new(text, page, event))
