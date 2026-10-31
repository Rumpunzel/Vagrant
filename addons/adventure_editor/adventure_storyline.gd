@tool
class_name AdventureStoryline
extends RefCounted

## An encounter's story as a table, worked out from the content: a column per stage (by track); a row per event, ticked where it needs a stage
## (stage conditions about the encounter), and under it a row per decision outcome in its pages, ticked where it sets one (stage consequences).
## Builds the changes ticking and unticking make, and those adding tracks, stages and events.

class Row:
	var event: AdventureEvent
	## None: the event's own row
	var decision: AdventureDecision
	var outcome: AdventureDecision.Outcome
	## The page holding [member decision]
	var page: AdventurePage

var encounter: AdventureEncounter
## [track, stage] per column
var columns: Array[Array] = [ ]
var rows: Array[Row] = [ ]

func _init(of: AdventureEncounter) -> void:
	encounter = of
	for track: AdventureStageTrack in of.tracks:
		if track != null: for stage: String in track.stages: columns.append([track, stage])
	for event: AdventureEvent in of.get_listed_events():
		if event is AdventureEventScenario: continue
		var row: Row = Row.new()
		row.event = event
		rows.append(row)
		for page: AdventurePage in AdventureEventGraph.new(event).pages: _add_outcome_rows(event, page)

## An event needs [param stage] of [param track]; an outcome sets it
func is_ticked(row: Row, track: AdventureStageTrack, stage: String) -> bool:
	if row.decision == null:
		var condition: AdventureStageCondition = _find_condition(row.event, track.name)
		return condition != null and condition.stages.has(stage)
	var consequence: AdventureStageConsequence = _find_consequence(row, track.name)
	return consequence != null and consequence.stage == stage

## The stages [param row] names that aren't in their track (typos)
func get_unknown_stages(row: Row) -> Array[String]:
	var unknown: Array[String] = [ ]
	for track: AdventureStageTrack in encounter.tracks:
		if track == null: continue
		var named: Array[String] = [ ]
		if row.decision == null:
			var condition: AdventureStageCondition = _find_condition(row.event, track.name)
			if condition != null: named = condition.stages
		else:
			var consequence: AdventureStageConsequence = _find_consequence(row, track.name)
			if consequence != null: named = [consequence.stage]
		for stage: String in named: if not track.stages.has(stage): unknown.append("%s: %s" % [track.name, stage])
	return unknown

## Ticking ([param on]) or unticking a cell: an event needs one of its ticked stages of a track (none ticked: no condition); an outcome sets
## at most one stage per track, so ticking another moves it
func get_changes_ticking(row: Row, track: AdventureStageTrack, stage: String, on: bool) -> Array[Array]:
	if row.decision == null: return _get_changes_needing(row.event, track.name, stage, on)
	var file: Resource = _get_file(row.decision, _get_file(row.event, encounter))
	var consequence: AdventureStageConsequence = _find_consequence(row, track.name)
	var none: Array[Array] = [ ]
	if on and consequence != null:
		if consequence.stage == stage: return none
		return [[consequence, &"stage", stage, file]]
	var consequences: Array[AdventureConsequence] = row.decision.get_consequences_of(row.outcome)
	if on: consequences.append(AdventureEventEditing.make_stage_consequence(track.name, stage))
	elif consequence != null and consequence.stage == stage: consequences.erase(consequence)
	else: return none
	return [[row.decision, row.outcome.consequences_property, consequences, file]]

func get_changes_adding_stage(track: AdventureStageTrack, stage: String) -> Array[Array]:
	if track.stages.has(stage): return [ ]
	var stages: Array[String] = track.stages.duplicate()
	stages.append(stage)
	return [[track, &"stages", stages, encounter]]

## A track without stages yet
func get_changes_adding_track(track_name: String) -> Array[Array]:
	var track: AdventureStageTrack = AdventureEventEditing.make_track(track_name)
	var tracks: Array[AdventureStageTrack] = encounter.tracks.duplicate()
	tracks.append(track)
	return [[encounter, &"tracks", tracks, encounter]]

## A new event of the encounter needing [param stage] of [param track]: its file (path -> event), next to the encounter's
func make_event_files(title: String, track: AdventureStageTrack, stage: String) -> Dictionary[String, Resource]:
	var event: AdventureEvent = AdventureEventEditing.make_event(title, false)
	event.conditions = [AdventureEventEditing.make_stage_condition(track.name, stage)] as Array[AdventureCondition]
	var files: Dictionary[String, Resource] = {}
	files[encounter.resource_path.get_base_dir().path_join(AdventureMapEditing.get_file_name(title))] = event
	return files

## Listing [param event] last among the encounter's events
func get_changes_listing(event: AdventureEvent) -> Array[Array]:
	var events: Array[AdventureEvent] = encounter.events.duplicate()
	events.append(event)
	return AdventureEventEditing.get_changes_listing(encounter, events)

func _add_outcome_rows(event: AdventureEvent, page: AdventurePage) -> void:
	for decision: AdventureDecision in page.decisions:
		if decision == null: continue
		for outcome: AdventureDecision.Outcome in decision.get_outcomes():
			# Fleeing and a draw have no consequences
			if outcome.consequences_property.is_empty(): continue
			var row: Row = Row.new()
			row.event = event
			row.decision = decision
			row.outcome = outcome
			row.page = page
			rows.append(row)

func _get_changes_needing(event: AdventureEvent, track_name: String, stage: String, on: bool) -> Array[Array]:
	var file: Resource = _get_file(event, encounter)
	var condition: AdventureStageCondition = _find_condition(event, track_name)
	var conditions: Array[AdventureCondition] = event.conditions.duplicate()
	if condition == null:
		if not on: return [ ]
		conditions.append(AdventureEventEditing.make_stage_condition(track_name, stage))
		return [[event, &"conditions", conditions, file]]
	var stages: Array[String] = condition.stages.duplicate()
	if on == stages.has(stage): return [ ]
	if on: stages.append(stage)
	else: stages.erase(stage)
	if not stages.is_empty(): return [[condition, &"stages", stages, file]]
	conditions.erase(condition)
	return [[event, &"conditions", conditions, file]]

func _find_condition(event: AdventureEvent, track_name: String) -> AdventureStageCondition:
	for condition: AdventureCondition in event.conditions:
		var stage_condition: AdventureStageCondition = condition as AdventureStageCondition
		if stage_condition != null and stage_condition.track == track_name and _is_about_it(stage_condition.subject): return stage_condition
	return null

func _find_consequence(row: Row, track_name: String) -> AdventureStageConsequence:
	for consequence: AdventureConsequence in row.decision.get_consequences_of(row.outcome):
		var stage_consequence: AdventureStageConsequence = consequence as AdventureStageConsequence
		if stage_consequence != null and stage_consequence.track == track_name and _is_about_it(stage_consequence.subject): return stage_consequence
	return null

## An empty subject is the encounter of the event
func _is_about_it(subject: String) -> bool:
	return subject.is_empty() or Files.load_existing(subject) == encounter

## The file [param resource] is stored in; [param fallback] while it is stored nowhere yet
static func _get_file(resource: Resource, fallback: Resource) -> Resource:
	if resource.resource_path.is_empty(): return fallback
	return resource if not resource.resource_path.contains("::") else load(AdventureEventEditing.get_file_path(resource))
