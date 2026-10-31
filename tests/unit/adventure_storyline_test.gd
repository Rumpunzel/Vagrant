extends GdUnitTestSuite

## The adventure editor's storyline table: a column per stage, a row per event (needs) and per decision outcome (sets), and what ticking does.

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
	_hearing = _event("Hearing", ["Unmet"])
	_eleanor = AdventureEncounter.new()
	_eleanor.tracks = [_storyline_track] as Array[AdventureStageTrack]
	_eleanor.events = [_meeting, _hearing] as Array[AdventureEvent]

func test_a_row_per_event_and_outcome_a_column_per_stage() -> void:
	var table: AdventureStoryline = AdventureStoryline.new(_eleanor)
	assert_int(table.columns.size()).is_equal(2)
	assert_str(table.columns[1][1]).is_equal("Met")
	assert_int(table.rows.size()).is_equal(3)
	assert_object(table.rows[1].decision).is_same(_greet)
	assert_bool(table.is_ticked(table.rows[0], _storyline_track, "Unmet")).is_true()
	assert_bool(table.is_ticked(table.rows[0], _storyline_track, "Met")).is_false()
	assert_bool(table.is_ticked(table.rows[1], _storyline_track, "Met")).is_true()
	assert_object(table.rows[2].event).is_same(_hearing)

func test_ticking_what_an_event_needs() -> void:
	var table: AdventureStoryline = AdventureStoryline.new(_eleanor)
	var condition: AdventureStageCondition = _meeting.conditions[0]
	assert_array(table.get_changes_ticking(table.rows[0], _storyline_track, "Met", true)).is_equal([[condition, &"stages", ["Unmet", "Met"], _eleanor]])
	# The last stage unticked: no condition any more
	assert_array(table.get_changes_ticking(table.rows[0], _storyline_track, "Unmet", false)).is_equal([[_meeting, &"conditions", [ ], _eleanor]])
	var rumour: AdventureEvent = _event("Rumour", [ ])
	_eleanor.events.append(rumour)
	var with_rumour: AdventureStoryline = AdventureStoryline.new(_eleanor)
	var changes: Array[Array] = with_rumour.get_changes_ticking(with_rumour.rows[3], _storyline_track, "Met", true)
	assert_array((changes[0][2] as Array)[0].stages).contains_exactly(["Met"])

func test_ticking_what_an_outcome_sets() -> void:
	var table: AdventureStoryline = AdventureStoryline.new(_eleanor)
	var met: AdventureStageConsequence = _greet.consequences[0]
	# One stage per track: ticking another moves it
	assert_array(table.get_changes_ticking(table.rows[1], _storyline_track, "Unmet", true)).is_equal([[met, &"stage", "Unmet", _eleanor]])
	assert_array(table.get_changes_ticking(table.rows[1], _storyline_track, "Met", false)).is_equal([[_greet, &"consequences", [ ], _eleanor]])
	_greet.consequences = [ ] as Array[AdventureConsequence]
	var changes: Array[Array] = table.get_changes_ticking(table.rows[1], _storyline_track, "Met", true)
	assert_str(changes[0][1]).is_equal("consequences")
	assert_str(((changes[0][2] as Array)[0] as AdventureStageConsequence).stage).is_equal("Met")

func test_tracks_stages_events_and_typos() -> void:
	var table: AdventureStoryline = AdventureStoryline.new(_eleanor)
	assert_array(table.get_changes_adding_stage(_storyline_track, "Gone")).is_equal([[_storyline_track, &"stages", ["Unmet", "Met", "Gone"], _eleanor]])
	assert_array(table.get_changes_adding_stage(_storyline_track, "Met")).is_empty()
	var tracks: Array = table.get_changes_adding_track("Mood")[0][2]
	assert_str((tracks[1] as AdventureStageTrack).name).is_equal("Mood")
	_eleanor.resource_path = "res://encounters/eleanor/eleanor.tres"
	var files: Dictionary[String, Resource] = table.make_event_files("Farewell", _storyline_track, "Met")
	assert_array(files.keys()).contains_exactly(["res://encounters/eleanor/farewell.tres"])
	assert_array((files.values()[0] as AdventureEvent).conditions[0].stages).contains_exactly(["Met"])
	(_meeting.conditions[0] as AdventureStageCondition).stages = ["Unmett"] as Array[String]
	assert_array(table.get_unknown_stages(table.rows[0])).contains_exactly(["Storyline: Unmett"])

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
