extends GdUnitTestSuite

## Nearby events: shown around the locations their source event is on, within their reach, when their own conditions are met.

class Switch extends AdventureCondition:
	var on: bool

	func _init(is_on: bool) -> void: on = is_on
	func is_true(_story: Story, _page: AdventurePage) -> bool: return on

var _story: Story
var _beach: AdventureArea
var _shore: AdventurePage
var _castle: AdventurePage
var _source: AdventurePage
var _heard: AdventurePage

func before_test() -> void:
	_story = auto_free(Story.new())
	_beach = AdventureArea.new()
	_shore = _location("Shore", _beach)
	_castle = _location("Castle", _beach)
	_link(_shore, _castle)
	_source = _page("Woman", "She knocks.")
	_heard = _page("", "You hear knocking.")
	_source.nearby_events = [_heard] as Array[AdventurePage]
	_castle.events = [_source] as Array[AdventurePage]

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
	var far: AdventurePage = _location("Far", _beach)
	_link(far, _shore)
	assert_array(_story.get_nearby_events(far)).is_empty()
	_heard.nearby_reach = 2
	_story._nearby_events.clear()
	assert_array(_story.get_nearby_events(far)).contains_exactly([_heard])

func test_reach_zero_is_the_whole_area() -> void:
	var swamp: AdventurePage = _location("Swamp", AdventureArea.new())
	var far: AdventurePage = _location("Far", _beach)
	_link(swamp, _castle)
	_link(far, swamp)
	_heard.nearby_reach = 0
	# Another area: not, however near
	assert_array(_story.get_nearby_events(swamp)).is_empty()
	# The same area: also two links away, even through another area
	assert_array(_story.get_nearby_events(far)).contains_exactly([_heard])

func test_pages_without_area_get_none() -> void:
	var inside: AdventurePage = _page("Inside", "")
	_link(inside, _castle)
	assert_array(_story.get_nearby_events(inside)).is_empty()

func test_scenario_options_are_sources() -> void:
	var scenario: AdventureEventScenario = AdventureEventScenario.new()
	scenario.events = [_source] as Array[AdventurePage]
	_castle.events = [scenario] as Array[AdventurePage]
	assert_array(_story.get_nearby_events(_shore)).contains_exactly([_heard])

func test_not_twice_when_listed_on_the_page() -> void:
	_shore.events = [_heard] as Array[AdventurePage]
	assert_array(_story.get_nearby_events(_shore)).is_empty()

func _location(title: String, area: AdventureArea) -> AdventurePage:
	var page: AdventurePage = _page(title, "Damp.")
	page.area = area
	return page

func _page(title: String, description: String) -> AdventurePage:
	var page: AdventurePage = AdventurePage.new()
	page.title = title
	page.description = description
	return page

func _link(from: AdventurePage, to: AdventurePage) -> void:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.transition = to
	from.decisions.append(decision)
