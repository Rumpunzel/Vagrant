@tool
class_name AdventureStoryline
extends RefCounted

## How an encounter's events and its stages fit together, worked out from the content: which stages an event can happen in (its stage conditions
## about the encounter; none on a track: any stage) and which stages its decisions lead to (stage consequences anywhere in its pages).
## A monster encounter's body is shown like a track ([constant BODY]): its monster condition, and where fights against it (won: beaten) and kills
## (dead) lead; it is in one of its states at a time. Builds the changes toggling a stage an event can happen in makes, and those adding tracks
## and stages.

## A decision outcome leading to a stage
class Lead:
	var decision: AdventureDecision
	var outcome: AdventureDecision.Outcome
	var page: AdventurePage
	var track: String
	var stage: String

## The name a monster encounter's body goes by among its tracks
const BODY: String = "Body"
const BODY_STATES: Dictionary[AdventureMonsterCondition.State, String] = {
	AdventureMonsterCondition.State.CAN_FIGHT: "can fight", AdventureMonsterCondition.State.BEATEN: "beaten", AdventureMonsterCondition.State.DEAD: "dead",
}

var encounter: AdventureEncounter

func _init(of: AdventureEncounter) -> void:
	encounter = of

## Whether it has a monster, whose body shows like a track
func has_body() -> bool: return encounter.profile is MonsterProfile

## Its tracks' names, the body first if it has one
func get_track_names() -> Array[String]:
	var names: Array[String] = [ ]
	if has_body(): names.append(BODY)
	for track: AdventureStageTrack in encounter.tracks: if track != null: names.append(track.name)
	return names

## The stages of [param track] (the body: its states)
func get_stages_of(track: String) -> Array[String]:
	var stages: Array[String] = [ ]
	if track == BODY: stages.assign(BODY_STATES.values())
	else:
		var found: AdventureStageTrack = AdventureStageTrack.find(encounter.tracks, track)
		if found != null: stages = found.stages.duplicate()
	return stages

## The stages of [param track] [param event] can happen in; empty: any
func get_stages_in(event: AdventureEvent, track: String) -> Array[String]:
	var stages: Array[String] = [ ]
	if track == BODY:
		var body: AdventureMonsterCondition = _find_body_condition(event)
		if body != null: stages.append(BODY_STATES[body.state])
		return stages
	var condition: AdventureStageCondition = _find_condition(event, track)
	if condition != null: stages = condition.stages.duplicate()
	return stages

func can_happen_in(event: AdventureEvent, track: String, stage: String) -> bool:
	var stages: Array[String] = get_stages_in(event, track)
	return stages.is_empty() or stages.has(stage)

## What [param event]'s decisions (also on the pages behind it) lead to: stages they set; for a monster, fights against it won (beaten) and
## kills (dead)
func get_leads(event: AdventureEvent) -> Array[Lead]:
	var leads: Array[Lead] = [ ]
	for page: AdventurePage in AdventureEventGraph.new(event).pages:
		for decision: AdventureDecision in page.decisions:
			if decision == null: continue
			var outcomes: Array[AdventureDecision.Outcome] = decision.get_outcomes()
			var fight: AdventureFightDecision = decision as AdventureFightDecision
			if has_body() and fight != null and fight.enemies.is_empty() and _is_about_it(fight.encounter):
				leads.append(_make_lead(decision, outcomes[0], page, BODY, BODY_STATES[AdventureMonsterCondition.State.BEATEN]))
			for outcome: AdventureDecision.Outcome in outcomes:
				for consequence: AdventureConsequence in decision.get_consequences_of(outcome):
					var stage_consequence: AdventureStageConsequence = consequence as AdventureStageConsequence
					var kill: AdventureKillConsequence = consequence as AdventureKillConsequence
					if stage_consequence != null and _is_about_it(stage_consequence.subject):
						leads.append(_make_lead(decision, outcome, page, stage_consequence.track, stage_consequence.stage))
					elif kill != null and has_body() and _is_about_it(kill.encounter):
						leads.append(_make_lead(decision, outcome, page, BODY, BODY_STATES[AdventureMonsterCondition.State.DEAD]))
	return leads

static func _make_lead(decision: AdventureDecision, outcome: AdventureDecision.Outcome, page: AdventurePage, track: String, stage: String) -> Lead:
	var lead: Lead = Lead.new()
	lead.decision = decision
	lead.outcome = outcome
	lead.page = page
	lead.track = track
	lead.stage = stage
	return lead

## Whether some decision of [param event] leads to [param stage] of [param track]
func leads_into(event: AdventureEvent, track: String, stage: String) -> bool:
	return get_leads(event).any(func(lead: Lead) -> bool: return lead.track == track and lead.stage == stage)

## The stages [param event] names (as where it can happen or where it leads) that their track doesn't have (typos), as "Track: Stage"
func get_unknown_stages(event: AdventureEvent) -> Array[String]:
	var unknown: Array[String] = [ ]
	var named: Array[Array] = [ ]
	for track: AdventureStageTrack in encounter.tracks:
		if track != null: for stage: String in get_stages_in(event, track.name): named.append([track.name, stage])
	for lead: Lead in get_leads(event): if lead.track != BODY: named.append([lead.track, lead.stage])
	for pair: Array in named:
		var track: AdventureStageTrack = AdventureStageTrack.find(encounter.tracks, pair[0])
		var text: String = "%s: %s" % pair
		if (track == null or not track.stages.has(pair[1])) and not unknown.has(text): unknown.append(text)
	return unknown

## Toggling whether [param event] can happen in [param stage] of [param track]: the stages ticked make one condition; none left: no condition.
## The body is in one state at a time: picking one replaces the other, picking it again drops the condition.
func get_changes_toggling(event: AdventureEvent, track: String, stage: String) -> Array[Array]:
	if track == BODY: return _get_changes_toggling_body(event, stage)
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

## Its other conditions (not about the encounter's stages or body), described
func describe_other_conditions(event: AdventureEvent) -> String:
	var others: Array[AdventureCondition] = [ ]
	for condition: AdventureCondition in event.conditions:
		var stage_condition: AdventureStageCondition = condition as AdventureStageCondition
		var body: AdventureMonsterCondition = condition as AdventureMonsterCondition
		if stage_condition != null and _is_about_it(stage_condition.subject): continue
		if body != null and has_body() and _is_about_it(body.encounter): continue
		others.append(condition)
	return AdventureEventOverview.get_condition_text(others)

func _get_changes_toggling_body(event: AdventureEvent, stage: String) -> Array[Array]:
	var file: Resource = AdventureEventEditing.get_file(event, encounter)
	var state: AdventureMonsterCondition.State = BODY_STATES.find_key(stage)
	var body: AdventureMonsterCondition = _find_body_condition(event)
	var conditions: Array[AdventureCondition] = event.conditions.duplicate()
	if body == null:
		conditions.append(AdventureEventEditing.make_monster_condition(state))
		return [[event, &"conditions", conditions, file]]
	if body.state != state: return [[body, &"state", state, file]]
	conditions.erase(body)
	return [[event, &"conditions", conditions, file]]

func _find_body_condition(event: AdventureEvent) -> AdventureMonsterCondition:
	for condition: AdventureCondition in event.conditions:
		var body: AdventureMonsterCondition = condition as AdventureMonsterCondition
		if body != null and _is_about_it(body.encounter): return body
	return null

func _find_condition(event: AdventureEvent, track: String) -> AdventureStageCondition:
	for condition: AdventureCondition in event.conditions:
		var stage_condition: AdventureStageCondition = condition as AdventureStageCondition
		if stage_condition != null and stage_condition.track == track and _is_about_it(stage_condition.subject): return stage_condition
	return null

## An empty subject is the encounter of the event
func _is_about_it(subject: String) -> bool:
	return subject.is_empty() or Files.load_existing(subject) == encounter
