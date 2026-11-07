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

func test_a_monster_s_body_shows_like_a_track() -> void:
	_eleanor.profile = TestMonsters.cutthroat()
	var story: AdventureStoryline = AdventureStoryline.new(_eleanor)
	assert_array(story.get_track_names()).contains_exactly(["Body", "Storyline"])
	assert_array(story.get_stages_of("Body")).contains_exactly(["can fight", "beaten", "dead"])
	var ambush: AdventureEvent = _event("Ambush", [ ])
	ambush.conditions = [AdventureMonsterCondition.new()] as Array[AdventureCondition]
	var fight: AdventureFightDecision = AdventureFightDecision.new()
	fight.description = "Fight!"
	var kill: AdventureDecision = AdventureDecision.new()
	kill.consequences = [AdventureKillConsequence.new()] as Array[AdventureConsequence]
	ambush.decisions = [fight, kill] as Array[AdventureDecision]
	assert_array(story.get_stages_in(ambush, "Body")).contains_exactly(["can fight"])
	var leads: Array = story.get_leads(ambush).map(func(lead: AdventureStoryline.Lead) -> String: return "%s %s" % [lead.outcome.name, lead.stage])
	assert_array(leads).contains_exactly(["Won beaten", " dead"])
	# One state at a time: another replaces it, the same one again drops the condition
	var condition: AdventureMonsterCondition = ambush.conditions[0]
	assert_array(story.get_changes_toggling(ambush, "Body", "beaten")).is_equal([[condition, &"state", AdventureMonsterCondition.State.BEATEN, _eleanor]])
	assert_array(story.get_changes_toggling(ambush, "Body", "can fight")).is_equal([[ambush, &"conditions", [ ], _eleanor]])

func test_renaming_a_track_or_stage_renames_what_names_it() -> void:
	var story: AdventureStoryline = AdventureStoryline.new(_eleanor)
	var stages: AdventureStageIndex = _stage_index()
	var condition: AdventureStageCondition = _meeting.conditions[0]
	var effect: AdventureStageConsequence = _greet.consequences[0]
	var changes: Array[Array] = story.get_changes_renaming_track(_storyline_track, "Friendship", stages)
	assert_array(changes.map(func(change: Array) -> Array: return [change[0], change[1], change[2]])).contains_exactly_in_any_order([
		[_storyline_track, &"name", "Friendship"], [condition, &"track", "Friendship"], [effect, &"track", "Friendship"],
	])
	changes = story.get_changes_renaming_stage(_storyline_track, "Met", "Friends", stages)
	assert_array(changes.map(func(change: Array) -> Array: return [change[0], change[1], change[2]])).contains_exactly_in_any_order([
		[_storyline_track, &"stages", ["Unmet", "Friends"]], [effect, &"stage", "Friends"],
	])

func test_only_what_nothing_uses_can_be_removed() -> void:
	var story: AdventureStoryline = AdventureStoryline.new(_eleanor)
	var stages: AdventureStageIndex = _stage_index()
	# The meeting needs Unmet, greeting her sets Met
	assert_int(story.count_uses(_storyline_track, stages)).is_equal(2)
	assert_int(story.count_uses(_storyline_track, stages, "Met")).is_equal(1)
	_greet.consequences = [] as Array[AdventureConsequence]
	assert_int(story.count_uses(_storyline_track, _stage_index(), "Met")).is_equal(0)
	assert_array(story.get_changes_removing_stage(_storyline_track, "Met")[0][2]).is_equal(["Unmet"])

func _stage_index() -> AdventureStageIndex:
	var shore: AdventureLocation = AdventureLocation.new()
	shore.area = AdventureArea.new()
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = shore
	adventure.encounters = [_eleanor] as Array[AdventureEncounter]
	return AdventureStageIndex.new(AdventureGraph.new(adventure), [_meeting, _hearing] as Array[AdventureEvent])

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
