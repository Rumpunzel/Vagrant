extends GdUnitTestSuite

## The adventure editor's storyline of an encounter: per track, which events need which stages and which stages they set.

var _eleanor: AdventureEncounter
var _meeting: AdventureEvent
var _hearing: AdventureEvent

func before_test() -> void:
	var storyline: AdventureStageTrack = AdventureStageTrack.new()
	storyline.name = "Storyline"
	storyline.stages = ["Unmet", "Met"] as Array[String]
	_meeting = _event("Meeting", ["Unmet"])
	var greet: AdventureDecision = AdventureDecision.new()
	greet.consequences = [_sets("Met")] as Array[AdventureConsequence]
	_meeting.decisions = [greet] as Array[AdventureDecision]
	_hearing = _event("Hearing", ["Unmet"])
	_eleanor = AdventureEncounter.new()
	_eleanor.tracks = [storyline] as Array[AdventureStageTrack]
	_eleanor.events = [_meeting, _hearing] as Array[AdventureEvent]

func test_events_between_the_stages_they_need_and_set() -> void:
	var story: AdventureStoryline = AdventureStoryline.new(_eleanor)
	assert_int(story.tracks.size()).is_equal(1)
	var steps: Array[AdventureStoryline.Step] = story.tracks[0].steps
	assert_array(steps.map(func(step: AdventureStoryline.Step) -> AdventureEvent: return step.event)).contains_exactly([_meeting, _hearing])
	assert_array(steps[0].needs).contains_exactly(["Unmet"])
	assert_array(steps[0].sets).contains_exactly(["Met"])
	assert_array(steps[1].sets).is_empty()
	assert_array(story.unstaged).is_empty()

func test_stages_set_on_pages_behind_the_event_count() -> void:
	var later: AdventurePage = AdventurePage.new()
	var leave: AdventureDecision = AdventureDecision.new()
	leave.consequences = [_sets("Gone")] as Array[AdventureConsequence]
	later.decisions = [leave] as Array[AdventureDecision]
	var go_on: AdventureDecision = AdventureDecision.new()
	go_on.transition = later
	_hearing.decisions = [go_on] as Array[AdventureDecision]
	var story: AdventureStoryline = AdventureStoryline.new(_eleanor)
	assert_array(story.tracks[0].steps[1].sets).contains_exactly(["Gone"])

func test_events_without_stages_and_other_subjects() -> void:
	var rumour: AdventureEvent = _event("Rumour", [ ])
	var about_other: AdventureStageCondition = AdventureStageCondition.new()
	about_other.subject = "res://somewhere/else.tres"
	about_other.track = "Storyline"
	about_other.stages = ["Met"] as Array[String]
	rumour.conditions = [about_other] as Array[AdventureCondition]
	_eleanor.events.append(rumour)
	var story: AdventureStoryline = AdventureStoryline.new(_eleanor)
	assert_array(story.unstaged).contains_exactly([rumour])

func _event(title: String, needs: Array[String]) -> AdventureEvent:
	var event: AdventureEvent = AdventureEvent.new()
	event.title = title
	if not needs.is_empty():
		var condition: AdventureStageCondition = AdventureStageCondition.new()
		condition.track = "Storyline"
		condition.stages = needs
		event.conditions = [condition] as Array[AdventureCondition]
	return event

func _sets(stage: String) -> AdventureStageConsequence:
	var consequence: AdventureStageConsequence = AdventureStageConsequence.new()
	consequence.track = "Storyline"
	consequence.stage = stage
	return consequence
