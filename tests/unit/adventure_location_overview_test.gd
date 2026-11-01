extends GdUnitTestSuite

## The adventure editor's location tab: what can happen at a location (its own events, encounters that could be there, near it or anywhere),
## in its order, and what can come there.

const RUIN_PATH: String = "user://location_overview_test_ruin.tres"

var _beach: AdventureArea
var _ruin: AdventureLocation
var _shore: AdventureLocation
var _eleanor: AdventureEncounter
var _meeting: AdventureEvent
var _hearing: AdventureEvent

func before_test() -> void:
	_beach = AdventureArea.new()
	_ruin = _location("Ruin")
	_shore = _location("Shore")
	_link(_ruin, _shore)
	_link(_shore, _ruin)
	_save(_ruin, RUIN_PATH)
	_meeting = _event("Meeting")
	_hearing = _event("Hearing")
	_hearing.where = AdventureEvent.Where.NEAR
	_eleanor = AdventureEncounter.new()
	_eleanor.title = "Eleanor"
	_eleanor.places = [RUIN_PATH] as Array[String]
	_eleanor.events = [_meeting, _hearing] as Array[AdventureEvent]

func after_test() -> void:
	if FileAccess.file_exists(RUIN_PATH): DirAccess.remove_absolute(RUIN_PATH)

func test_own_events_first_then_encounters_that_could_be_here() -> void:
	var wind: AdventureEvent = _event("Wind")
	TestAdventures.list(_ruin, [wind] as Array[AdventureEvent])
	var overview: AdventureLocationOverview = AdventureLocationOverview.new(_ruin, [_eleanor] as Array[AdventureEncounter])
	assert_int(overview.sections.size()).is_equal(2)
	assert_object(overview.sections[0].encounter).is_null()
	assert_array(overview.sections[0].events).contains_exactly([wind])
	assert_object(overview.sections[1].encounter).is_same(_eleanor)
	assert_array(overview.sections[1].events).contains_exactly([_meeting])
	assert_str(overview.sections[1].reason).is_equal("could be here")

func test_near_and_anywhere() -> void:
	var rumour: AdventureEvent = _event("Rumour")
	rumour.where = AdventureEvent.Where.ANYWHERE
	_eleanor.events.append(rumour)
	var overview: AdventureLocationOverview = AdventureLocationOverview.new(_shore, [_eleanor] as Array[AdventureEncounter])
	assert_array(overview.sections[1].events).contains_exactly([_hearing, rumour])
	assert_str(overview.sections[1].reason).is_equal("near it, anywhere")

func test_encounters_that_cannot_show_are_left_out() -> void:
	var far: AdventureLocation = _location("Far")
	var overview: AdventureLocationOverview = AdventureLocationOverview.new(far, [_eleanor] as Array[AdventureEncounter])
	assert_int(overview.sections.size()).is_equal(1)
	assert_object(overview.sections[0].encounter).is_null()

func test_what_can_come_here() -> void:
	var stranger: AdventureEncounter = AdventureEncounter.new()
	var waiting: AdventureEvent = _event("Waiting")
	stranger.events = [waiting] as Array[AdventureEvent]
	var follow: AdventureDecision = AdventureDecision.new()
	follow.description = "Follow me."
	var move: AdventureMoveConsequence = AdventureMoveConsequence.new()
	move.to = RUIN_PATH
	follow.consequences = [move] as Array[AdventureConsequence]
	var greeting: AdventureEvent = _event("Greeting")
	greeting.decisions = [follow] as Array[AdventureDecision]
	stranger.events.append(greeting)
	var overview: AdventureLocationOverview = AdventureLocationOverview.new(_ruin, [stranger] as Array[AdventureEncounter])
	assert_int(overview.arrivals.size()).is_equal(1)
	assert_object(overview.arrivals[0].encounter).is_same(stranger)
	assert_object(overview.arrivals[0].page).is_same(greeting)
	assert_object(overview.sections[1].encounter).is_same(stranger)
	assert_str(overview.sections[1].reason).is_equal("can come here")

func test_moving_a_section_writes_the_whole_order() -> void:
	var overview: AdventureLocationOverview = AdventureLocationOverview.new(_ruin, [_eleanor] as Array[AdventureEncounter])
	var eleanor_key: String = AdventureLayout.get_key(_eleanor)
	assert_array(overview.get_order_moving(1, -1)).contains_exactly([eleanor_key, AdventureLayout.get_key(_ruin)])
	_save(_eleanor, "user://location_overview_test_eleanor.tres")
	_ruin.order = ["user://location_overview_test_eleanor.tres", RUIN_PATH] as Array[String]
	var reordered: AdventureLocationOverview = AdventureLocationOverview.new(_ruin, [_eleanor] as Array[AdventureEncounter])
	assert_object(reordered.sections[0].encounter).is_same(_eleanor)
	DirAccess.remove_absolute("user://location_overview_test_eleanor.tres")

func _save(resource: Resource, path: String) -> void:
	ResourceSaver.save(resource, path)
	resource.take_over_path(path)

func _location(title: String) -> AdventureLocation:
	var location: AdventureLocation = AdventureLocation.new()
	location.title = title
	location.area = _beach
	return location

func _event(title: String) -> AdventureEvent:
	var event: AdventureEvent = AdventureEvent.new()
	event.title = title
	return event

func _link(from: AdventurePage, to: AdventurePage) -> void:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.transition = to
	from.decisions.append(decision)
