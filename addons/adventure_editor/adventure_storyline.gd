@tool
class_name AdventureStoryline
extends RefCounted

## An encounter's story at a glance, worked out from the content: per stage track, which of its events need which stages (stage conditions
## about it) and which stages they set (stage consequences about it, anywhere in the event's pages)

class Step:
	var event: AdventureEvent
	## The stages it needs; empty: any
	var needs: Array[String] = [ ]
	## The stages its pages set
	var sets: Array[String] = [ ]

class Track:
	var track: AdventureStageTrack
	var steps: Array[Step] = [ ]

var encounter: AdventureEncounter
var tracks: Array[Track] = [ ]
## Events that need and set no stage
var unstaged: Array[AdventureEvent] = [ ]

func _init(of: AdventureEncounter) -> void:
	encounter = of
	for track: AdventureStageTrack in of.tracks:
		if track == null: continue
		var line: Track = Track.new()
		line.track = track
		tracks.append(line)
	for event: AdventureEvent in of.get_listed_events():
		if event is AdventureEventScenario: continue
		var staged: bool = false
		for line: Track in tracks:
			var step: Step = _make_step(event, line.track.name)
			if step.needs.is_empty() and step.sets.is_empty(): continue
			line.steps.append(step)
			staged = true
		if not staged: unstaged.append(event)

func _make_step(event: AdventureEvent, track_name: String) -> Step:
	var step: Step = Step.new()
	step.event = event
	for condition: AdventureCondition in event.conditions:
		var stage_condition: AdventureStageCondition = condition as AdventureStageCondition
		if stage_condition == null or stage_condition.track != track_name or not _is_about_it(stage_condition.subject): continue
		for stage: String in stage_condition.stages: if not step.needs.has(stage): step.needs.append(stage)
	for page: AdventurePage in AdventureEventGraph.new(event).pages:
		for decision: AdventureDecision in page.decisions:
			if decision == null: continue
			for outcome: AdventureDecision.Outcome in decision.get_outcomes():
				for consequence: AdventureConsequence in decision.get_consequences_of(outcome):
					var stage_consequence: AdventureStageConsequence = consequence as AdventureStageConsequence
					if stage_consequence == null or stage_consequence.track != track_name or not _is_about_it(stage_consequence.subject): continue
					if not step.sets.has(stage_consequence.stage): step.sets.append(stage_consequence.stage)
	return step

## An empty subject is the encounter of the event
func _is_about_it(subject: String) -> bool:
	return subject.is_empty() or Files.load_existing(subject) == encounter
