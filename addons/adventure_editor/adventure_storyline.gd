@tool
class_name AdventureStoryline
extends RefCounted

## How an encounter's events and its stages fit together, worked out from the content: which stages an event can happen in (its stage conditions
## about the encounter; none on a track: any stage) and which stages its decisions lead to (stage consequences anywhere in its pages).
## Builds the changes toggling a stage an event can happen in makes, and those adding tracks and stages.

## A decision outcome leading to a stage
class Lead:
	var decision: AdventureDecision
	var outcome: AdventureDecision.Outcome
	var page: AdventurePage
	var track: String
	var stage: String

var encounter: AdventureEncounter

func _init(of: AdventureEncounter) -> void:
	encounter = of

## The stages of [param track] [param event] can happen in; empty: any
func get_stages_in(event: AdventureEvent, track: String) -> Array[String]:
	var condition: AdventureStageCondition = _find_condition(event, track)
	var stages: Array[String] = [ ]
	if condition != null: stages = condition.stages.duplicate()
	return stages

func can_happen_in(event: AdventureEvent, track: String, stage: String) -> bool:
	var stages: Array[String] = get_stages_in(event, track)
	return stages.is_empty() or stages.has(stage)

## What [param event]'s decisions (also on the pages behind it) lead to
func get_leads(event: AdventureEvent) -> Array[Lead]:
	var leads: Array[Lead] = [ ]
	for page: AdventurePage in AdventureEventGraph.new(event).pages:
		for decision: AdventureDecision in page.decisions:
			if decision == null: continue
			for outcome: AdventureDecision.Outcome in decision.get_outcomes():
				for consequence: AdventureConsequence in decision.get_consequences_of(outcome):
					var stage_consequence: AdventureStageConsequence = consequence as AdventureStageConsequence
					if stage_consequence == null or not _is_about_it(stage_consequence.subject): continue
					var lead: Lead = Lead.new()
					lead.decision = decision
					lead.outcome = outcome
					lead.page = page
					lead.track = stage_consequence.track
					lead.stage = stage_consequence.stage
					leads.append(lead)
	return leads

## Whether some decision of [param event] leads to [param stage] of [param track]
func leads_into(event: AdventureEvent, track: String, stage: String) -> bool:
	return get_leads(event).any(func(lead: Lead) -> bool: return lead.track == track and lead.stage == stage)

## The stages [param event] names (as where it can happen or where it leads) that their track doesn't have (typos), as "Track: Stage"
func get_unknown_stages(event: AdventureEvent) -> Array[String]:
	var unknown: Array[String] = [ ]
	var named: Array[Array] = [ ]
	for track: AdventureStageTrack in encounter.tracks:
		if track != null: for stage: String in get_stages_in(event, track.name): named.append([track.name, stage])
	for lead: Lead in get_leads(event): named.append([lead.track, lead.stage])
	for pair: Array in named:
		var track: AdventureStageTrack = AdventureStageTrack.find(encounter.tracks, pair[0])
		var text: String = "%s: %s" % pair
		if (track == null or not track.stages.has(pair[1])) and not unknown.has(text): unknown.append(text)
	return unknown

## Toggling whether [param event] can happen in [param stage] of [param track]: the stages ticked make one condition; none left: no condition
func get_changes_toggling(event: AdventureEvent, track: String, stage: String) -> Array[Array]:
	var file: Resource = AdventureEventEditing.get_file(event, encounter)
	var condition: AdventureStageCondition = _find_condition(event, track)
	var conditions: Array[AdventureCondition] = event.conditions.duplicate()
	if condition == null:
		conditions.append(AdventureEventEditing.make_stage_condition(track, stage))
		return [[event, &"conditions", conditions, file]]
	var stages: Array[String] = condition.stages.duplicate()
	if stages.has(stage): stages.erase(stage)
	else: stages.append(stage)
	if not stages.is_empty(): return [[condition, &"stages", stages, file]]
	conditions.erase(condition)
	return [[event, &"conditions", conditions, file]]

func get_changes_adding_stage(track: AdventureStageTrack, stage: String) -> Array[Array]:
	if track.stages.has(stage): return [ ]
	var stages: Array[String] = track.stages.duplicate()
	stages.append(stage)
	return [[track, &"stages", stages, encounter]]

## A track without stages yet
func get_changes_adding_track(track_name: String) -> Array[Array]:
	var tracks: Array[AdventureStageTrack] = encounter.tracks.duplicate()
	tracks.append(AdventureEventEditing.make_track(track_name))
	return [[encounter, &"tracks", tracks, encounter]]

## Its other conditions (not about the encounter's stages), described
func describe_other_conditions(event: AdventureEvent) -> String:
	var others: Array[AdventureCondition] = [ ]
	for condition: AdventureCondition in event.conditions:
		var stage_condition: AdventureStageCondition = condition as AdventureStageCondition
		if stage_condition == null or not _is_about_it(stage_condition.subject): others.append(condition)
	return AdventureEventOverview.get_condition_text(others)

func _find_condition(event: AdventureEvent, track: String) -> AdventureStageCondition:
	for condition: AdventureCondition in event.conditions:
		var stage_condition: AdventureStageCondition = condition as AdventureStageCondition
		if stage_condition != null and stage_condition.track == track and _is_about_it(stage_condition.subject): return stage_condition
	return null

## An empty subject is the encounter of the event
func _is_about_it(subject: String) -> bool:
	return subject.is_empty() or Files.load_existing(subject) == encounter
