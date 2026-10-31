extends GdUnitTestSuite

## The adventure editor's story of an encounter: which stages its events can happen in, where their decisions lead, and toggling stages.

var _storyline_track: AdventureStageTrack
var _eleanor: AdventureEncounter
var _meeting: AdventureEvent
var _greet: AdventureDecision
var _hearing: AdventureEvent

func before_test() -> void:
	_storyline_track = AdventureStageTrack.new()
	_storyline_track.name = "Storyline"
	_storyline_track.stages = ["Unmet", "Met"] as Array[String]
	_meeting = _event("Meeting", ["Unmet"])
	_greet = AdventureDecision.new()
	_greet.description = "Greet her."
	_greet.consequences = [_sets("Met")] as Array[AdventureConsequence]
	_meeting.decisions = [_greet] as Array[AdventureDecision]
	_hearing = _event("Hearing", [ ])
	_eleanor = AdventureEncounter.new()
	_eleanor.tracks = [_storyline_track] as Array[AdventureStageTrack]
	_eleanor.events = [_meeting, _hearing] as Array[AdventureEvent]

func test_where_events_happen_and_lead() -> void:
	var story: AdventureStoryline = AdventureStoryline.new(_eleanor)
	assert_array(story.get_stages_in(_meeting, "Storyline")).contains_exactly(["Unmet"])
	assert_bool(story.can_happen_in(_meeting, "Storyline", "Met")).is_false()
	# No stage condition on a track: any of its stages
	assert_array(story.get_stages_in(_hearing, "Storyline")).is_empty()
	assert_bool(story.can_happen_in(_hearing, "Storyline", "Met")).is_true()
	var leads: Array[AdventureStoryline.Lead] = story.get_leads(_meeting)
	assert_int(leads.size()).is_equal(1)
	assert_object(leads[0].decision).is_same(_greet)
	assert_str(leads[0].stage).is_equal("Met")
	assert_bool(story.leads_into(_meeting, "Storyline", "Met")).is_true()
	assert_bool(story.leads_into(_hearing, "Storyline", "Met")).is_false()

func test_leads_on_pages_behind_the_event_count() -> void:
	var later: AdventurePage = AdventurePage.new()
	var leave: AdventureDecision = AdventureDecision.new()
	leave.consequences = [_sets("Gone")] as Array[AdventureConsequence]
	later.decisions = [leave] as Array[AdventureDecision]
	var go_on: AdventureDecision = AdventureDecision.new()
	go_on.transition = later
	_hearing.decisions = [go_on] as Array[AdventureDecision]
	var story: AdventureStoryline = AdventureStoryline.new(_eleanor)
	assert_array(story.get_leads(_hearing).map(func(lead: AdventureStoryline.Lead) -> String: return lead.stage)).contains_exactly(["Gone"])
	# Gone is no stage of the track
	assert_array(story.get_unknown_stages(_hearing)).contains_exactly(["Storyline: Gone"])

func test_toggling_where_an_event_happens() -> void:
	var story: AdventureStoryline = AdventureStoryline.new(_eleanor)
	var condition: AdventureStageCondition = _meeting.conditions[0]
	assert_array(story.get_changes_toggling(_meeting, "Storyline", "Met")).is_equal([[condition, &"stages", ["Unmet", "Met"], _eleanor]])
	# The last stage off: no condition, any stage
	assert_array(story.get_changes_toggling(_meeting, "Storyline", "Unmet")).is_equal([[_meeting, &"conditions", [ ], _eleanor]])
	var changes: Array[Array] = story.get_changes_toggling(_hearing, "Storyline", "Met")
	assert_array(((changes[0][2] as Array)[0] as AdventureStageCondition).stages).contains_exactly(["Met"])

func test_tracks_stages_and_other_conditions() -> void:
	var story: AdventureStoryline = AdventureStoryline.new(_eleanor)
	assert_array(story.get_changes_adding_stage(_storyline_track, "Gone")).is_equal([[_storyline_track, &"stages", ["Unmet", "Met", "Gone"], _eleanor]])
	assert_array(story.get_changes_adding_stage(_storyline_track, "Met")).is_empty()
	var tracks: Array = story.get_changes_adding_track("Mood")[0][2]
	assert_str((tracks[1] as AdventureStageTrack).name).is_equal("Mood")
	_meeting.conditions.append(AdventurePlaceCondition.new())
	assert_str(story.describe_other_conditions(_meeting)).is_equal("It is here")

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
