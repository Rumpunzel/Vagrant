extends GdUnitTestSuite

## Nearby events: shown around the locations their source event is on, within their reach, when their own conditions are met.

class Switch extends AdventureCondition:
	var on: bool

	func _init(is_on: bool) -> void: on = is_on
	func is_true(_story: Story, _page: AdventurePage) -> bool: return on

var _story: Story
var _beach: AdventureArea
var _shore: AdventureLocation
var _castle: AdventureLocation
var _source: AdventureEvent
var _heard: AdventureEvent

func before_test() -> void:
	_story = auto_free(Story.new())
	_beach = AdventureArea.new()
	_shore = _location("Shore", _beach)
	_castle = _location("Castle", _beach)
	_link(_shore, _castle)
	_source = _event("Woman", "She knocks.")
	_heard = _event("", "You hear knocking.")
	_source.nearby_events = [_heard] as Array[AdventureEvent]
	_castle.events = [_source] as Array[AdventureEvent]

func test_shows_on_linked_locations() -> void:
	assert_array(_story.get_nearby_events(_shore)).contains_exactly([_heard])
	assert_array(_shore.get_events(_story)).contains_exactly([_heard])
	assert_str(_shore.get_description(_story)).is_equal("[p]Damp.[/p][p]You hear knocking.[/p]")
	assert_array(_shore.find_nearby_events()).contains_exactly([[_heard, _castle]])

func test_not_on_the_source_location_itself() -> void:
	assert_array(_story.get_nearby_events(_castle)).is_empty()

func test_own_conditions_decide() -> void:
	_heard.conditions = [Switch.new(false)] as Array[AdventureCondition]
	assert_array(_shore.get_events(_story)).is_empty()

func test_reach_counts_links() -> void:
	var far: AdventureLocation = _location("Far", _beach)
	_link(far, _shore)
	assert_array(_story.get_nearby_events(far)).is_empty()
	_heard.nearby_reach = 2
	_story._nearby_events.clear()
	assert_array(_story.get_nearby_events(far)).contains_exactly([_heard])

func test_reach_zero_is_the_whole_area() -> void:
	var swamp: AdventureLocation = _location("Swamp", AdventureArea.new())
	var far: AdventureLocation = _location("Far", _beach)
	_link(swamp, _castle)
	_link(far, swamp)
	_heard.nearby_reach = 0
	# Another area: not, however near
	assert_array(_story.get_nearby_events(swamp)).is_empty()
	# The same area: also two links away, even through another area
	assert_array(_story.get_nearby_events(far)).contains_exactly([_heard])

func test_staying_in_the_area() -> void:
	var swamp: AdventureLocation = _location("Swamp", AdventureArea.new())
	_link(swamp, _castle)
	assert_array(_story.get_nearby_events(swamp)).contains_exactly([_heard])
	_heard.nearby_stays_in_area = true
	_story._nearby_events.clear()
	assert_array(_story.get_nearby_events(swamp)).is_empty()
	assert_array(_story.get_nearby_events(_shore)).contains_exactly([_heard])

func test_plain_pages_get_none() -> void:
	var inside: AdventurePage = AdventurePage.new()
	_link(inside, _castle)
	assert_array(inside.get_events(_story)).is_empty()

func test_scenario_options_are_sources() -> void:
	var scenario: AdventureEventScenario = AdventureEventScenario.new()
	scenario.events = [_source] as Array[AdventureEvent]
	_castle.events = [scenario] as Array[AdventureEvent]
	assert_array(_story.get_nearby_events(_shore)).contains_exactly([_heard])

func test_not_twice_when_listed_on_the_page() -> void:
	_shore.events = [_heard] as Array[AdventureEvent]
	assert_array(_story.get_nearby_events(_shore)).is_empty()

func _location(title: String, area: AdventureArea) -> AdventureLocation:
	var location: AdventureLocation = AdventureLocation.new()
	location.title = title
	location.description = "Damp."
	location.area = area
	return location

func _event(title: String, description: String) -> AdventureEvent:
	var event: AdventureEvent = AdventureEvent.new()
	event.title = title
	event.description = description
	return event

func _link(from: AdventurePage, to: AdventurePage) -> void:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.transition = to
	from.decisions.append(decision)
