@tool
class_name AdventureStageIndex
extends RefCounted

## Where each stage of an adventure is set (stage effects of the decisions of locations and events) and needed (stage conditions of events),
## by subject, track and stage. An empty subject means the event's own: its encounter, else the locations it is on.

## A decision setting a stage, on [member page] of [member event] (none: of a location)
class Setter:
	var decision: AdventureDecision
	var page: AdventurePage
	var event: AdventureEvent

	func _init(by: AdventureDecision, on: AdventurePage, of: AdventureEvent) -> void:
		decision = by
		page = on
		event = of

var _graph: AdventureGraph
## key -> Array[Setter]
var _setters: Dictionary[String, Array] = {}
## key -> Array[AdventureEvent]
var _needers: Dictionary[String, Array] = {}
## A stage condition or effect -> what it is about
var _subjects: Dictionary[Resource, Array] = {}

## [param events]: the events to look through (the map's: [member AdventureGraph.event_hosts])
func _init(graph: AdventureGraph, events: Array[AdventureEvent]) -> void:
	_graph = graph
	for page: AdventurePage in graph.pages:
		if page is AdventureLocation: _note_decisions(page, null, [page] as Array[Resource])
	for event: AdventureEvent in events:
		var own: Array[Resource] = get_own_subjects(event)
		for condition: AdventureCondition in event.conditions:
			var needs: AdventureStageCondition = condition as AdventureStageCondition
			if needs == null: continue
			var subjects: Array[Resource] = _note_subjects(needs, needs.subject, own)
			for subject: Resource in subjects:
				for stage: String in needs.stages: _add(_needers, _key(subject, needs.track, stage), event)
		if event is AdventureEventScenario: continue
		for page: AdventurePage in AdventureEventGraph.new(event).pages: _note_decisions(page, event, own)

## What an empty subject means in [param event]: its encounter, else the locations it is on
func get_own_subjects(event: AdventureEvent) -> Array[Resource]:
	var subjects: Array[Resource] = [ ]
	var encounter: AdventureEncounter = _graph.get_encounter_of(event)
	if encounter != null: subjects.append(encounter)
	else: subjects.append_array(_graph.get_location_hosts(event))
	return subjects

## What a stage condition or effect is about; one met nowhere: what its subject names
func get_subjects(of: Resource) -> Array[Resource]:
	var subjects: Array[Resource] = [ ]
	if _subjects.has(of): subjects.assign(_subjects[of])
	else:
		var path: String = of.get(&"subject")
		subjects = resolve(path, [ ] as Array[Resource])
	return subjects

func get_setters(subject: Resource, track: String, stage: String) -> Array[Setter]:
	var setters: Array[Setter] = [ ]
	setters.assign(_setters.get(_key(subject, track, stage), [ ]))
	return setters

func get_needers(subject: Resource, track: String, stage: String) -> Array[AdventureEvent]:
	var events: Array[AdventureEvent] = [ ]
	events.assign(_needers.get(_key(subject, track, stage), [ ]))
	return events

## Whether [param subject] starts in [param stage] (the first of its track)
static func is_start(subject: Resource, track: String, stage: String) -> bool:
	var found: AdventureStageTrack = AdventureStageTrack.find(AdventureStageTrack.get_tracks_of(subject), track)
	return found != null and not found.stages.is_empty() and found.stages[0] == stage

## Whether [param subject] can be in [param stage]: it starts there, or something sets it
func can_reach(subject: Resource, track: String, stage: String) -> bool:
	return is_start(subject, track, stage) or _setters.has(_key(subject, track, stage))

static func resolve(path: String, own: Array[Resource]) -> Array[Resource]:
	if path.is_empty(): return own
	var subjects: Array[Resource] = [ ]
	var subject: Resource = Files.load_existing(path)
	if subject != null: subjects.append(subject)
	return subjects

func _note_decisions(page: AdventurePage, event: AdventureEvent, own: Array[Resource]) -> void:
	for decision: AdventureDecision in page.decisions:
		if decision == null: continue
		for outcome: AdventureDecision.Outcome in decision.get_outcomes():
			for consequence: AdventureConsequence in decision.get_consequences_of(outcome):
				var sets: AdventureStageConsequence = consequence as AdventureStageConsequence
				if sets == null: continue
				for subject: Resource in _note_subjects(sets, sets.subject, own):
					_add(_setters, _key(subject, sets.track, sets.stage), Setter.new(decision, page, event))

func _note_subjects(of: Resource, path: String, own: Array[Resource]) -> Array[Resource]:
	var subjects: Array[Resource] = resolve(path, own)
	var known: Array = _subjects.get_or_add(of, [ ])
	for subject: Resource in subjects: if not known.has(subject): known.append(subject)
	return subjects

static func _add(into: Dictionary[String, Array], key: String, value: Variant) -> void:
	var values: Array = into.get_or_add(key, [ ])
	if not values.has(value): values.append(value)

static func _key(subject: Resource, track: String, stage: String) -> String: return "%d|%s|%s" % [subject.get_instance_id(), track, stage]
