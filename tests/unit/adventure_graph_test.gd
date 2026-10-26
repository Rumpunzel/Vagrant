extends GdUnitTestSuite

## The adventure editor's map: which pages become nodes, their areas and the links between them.

var _beach: AdventureArea
var _swamp: AdventureArea

func before_test() -> void:
	_beach = AdventureArea.new()
	_swamp = AdventureArea.new()

func test_no_adventure_is_empty() -> void:
	var graph: AdventureGraph = AdventureGraph.new(null)
	assert_array(graph.pages).is_empty()
	assert_array(graph.links).is_empty()

func test_walks_links_from_the_starting_page() -> void:
	var shore: AdventurePage = _location("Shore", _beach)
	var ruin: AdventurePage = _location("Ruin", _beach)
	var temple: AdventurePage = _location("Temple", _swamp)
	_link(shore, ruin)
	_link(ruin, temple)
	_link(ruin, shore)
	var graph: AdventureGraph = AdventureGraph.new(_adventure(shore))
	assert_array(graph.pages).contains_exactly([shore, ruin, temple])
	assert_array(graph.areas).contains_exactly([_beach, _swamp])
	assert_int(graph.links.size()).is_equal(3)
	assert_bool(graph.get_link(ruin, shore).through_event).is_false()

func test_unreachable_pages_are_left_out() -> void:
	var shore: AdventurePage = _location("Shore", _beach)
	_link(_location("Ruin", _beach), shore)
	assert_array(AdventureGraph.new(_adventure(shore)).pages).contains_exactly([shore])

func test_turn_back_and_self_links_draw_nothing() -> void:
	var shore: AdventurePage = _location("Shore", _beach)
	shore.decisions.append(AdventureDecision.new())
	_link(shore, shore)
	var graph: AdventureGraph = AdventureGraph.new(_adventure(shore))
	assert_array(graph.pages).contains_exactly([shore])
	assert_array(graph.links).is_empty()

func test_every_transition_of_a_decision_links() -> void:
	var ruin: AdventurePage = _location("Ruin", _beach)
	var won: AdventurePage = _location("Won", _beach)
	var lost: AdventurePage = _location("Lost", _beach)
	var save: AdventureSaveDecision = AdventureSaveDecision.new()
	save.transition = won
	save.failure_transition = lost
	ruin.decisions.append(save)
	assert_array(AdventureGraph.new(_adventure(ruin)).pages).contains_exactly_in_any_order([ruin, won, lost])

func test_pages_without_area_linked_directly_are_nodes() -> void:
	var shore: AdventurePage = _location("Shore", _beach)
	var cave: AdventurePage = _location("Cave", null)
	_link(shore, cave)
	var graph: AdventureGraph = AdventureGraph.new(_adventure(shore))
	assert_array(graph.pages).contains_exactly([shore, cave])
	assert_array(graph.areas).contains_exactly([_beach])

func test_location_behind_an_event_links_from_the_host() -> void:
	var ruin: AdventurePage = _location("Ruin", _swamp)
	var temple: AdventurePage = _location("Temple", _swamp)
	var ambush: AdventurePage = _location("Ambush", null)
	var won: AdventurePage = _location("Won", null)
	ruin.events.append(ambush)
	_link(ambush, won)
	_link(won, temple)
	var graph: AdventureGraph = AdventureGraph.new(_adventure(ruin))
	assert_array(graph.pages).contains_exactly([ruin, temple])
	assert_bool(graph.get_link(ruin, temple).through_event).is_true()

func test_nested_events_are_walked() -> void:
	var ruin: AdventurePage = _location("Ruin", _swamp)
	var temple: AdventurePage = _location("Temple", _swamp)
	var ambush: AdventurePage = _location("Ambush", null)
	var inner: AdventurePage = _location("Inner", null)
	ruin.events.append(ambush)
	ambush.events.append(inner)
	_link(inner, temple)
	assert_bool(AdventureGraph.new(_adventure(ruin)).get_link(ruin, temple).through_event).is_true()

func test_direct_link_wins_over_one_through_an_event() -> void:
	var ruin: AdventurePage = _location("Ruin", _swamp)
	var temple: AdventurePage = _location("Temple", _swamp)
	var ambush: AdventurePage = _location("Ambush", null)
	ruin.events.append(ambush)
	_link(ambush, temple)
	_link(ruin, temple)
	var graph: AdventureGraph = AdventureGraph.new(_adventure(ruin))
	assert_int(graph.links.size()).is_equal(1)
	assert_bool(graph.get_link(ruin, temple).through_event).is_false()

func test_event_loops_end() -> void:
	var ruin: AdventurePage = _location("Ruin", _swamp)
	var ambush: AdventurePage = _location("Ambush", null)
	var lost: AdventurePage = _location("Lost", null)
	ruin.events.append(ambush)
	_link(ambush, lost)
	_link(lost, ambush)
	assert_array(AdventureGraph.new(_adventure(ruin)).pages).contains_exactly([ruin])

func test_collects_events_and_their_hosts() -> void:
	var ruin: AdventurePage = _location("Ruin", _swamp)
	var temple: AdventurePage = _location("Temple", _swamp)
	var ambush: AdventurePage = _location("Ambush", null)
	var nested: AdventurePage = _location("Nested", null)
	ruin.events.append(ambush)
	temple.events.append(ambush)
	ambush.events.append(nested)
	_link(ruin, temple)
	var graph: AdventureGraph = AdventureGraph.new(_adventure(ruin))
	assert_array(graph.event_hosts.keys()).contains_exactly([ambush, nested])
	assert_array(graph.get_hosts(ambush)).contains_exactly([ruin, temple])
	assert_array(graph.get_hosts(nested)).contains_exactly([ambush])
	assert_array(graph.get_hosts(ruin)).is_empty()

func test_location_hosts_and_top_events() -> void:
	var ruin: AdventurePage = _location("Ruin", _swamp)
	var temple: AdventurePage = _location("Temple", _swamp)
	var scenario: AdventureEventScenario = AdventureEventScenario.new()
	var ambush: AdventurePage = _location("Ambush", null)
	scenario.events.append(ambush)
	ruin.events.append(scenario)
	temple.events.append(scenario)
	_link(ruin, temple)
	var graph: AdventureGraph = AdventureGraph.new(_adventure(ruin))
	assert_array(graph.get_location_hosts(ambush)).contains_exactly([ruin, temple])
	assert_array(graph.get_top_events()).contains_exactly([scenario])
	# A host reference leads to no page on the map
	var back: AdventureDecision = AdventureDecision.new()
	back.transition = AdventureHostReference.new()
	ambush.decisions.append(back)
	assert_int(AdventureGraph.new(_adventure(ruin)).links.size()).is_equal(1)

func test_title_falls_back_to_capitalized_file_name() -> void:
	assert_str(AdventureGraph.get_title(_location("Shore", null))).is_equal("Shore")
	var untitled: AdventurePage = _location("", null)
	untitled.resource_path = "res://somewhere/rocky_shore.tres"
	assert_str(AdventureGraph.get_title(untitled)).is_equal("Rocky Shore")
	# Stored inside another file: the start of its text
	untitled.resource_path = ""
	untitled.description = "The woman turns around, slowly, as if she had expected you all along."
	assert_str(AdventureGraph.get_title(untitled)).is_equal("The woman turns around, slowly,…")
	untitled.description = ""
	assert_str(AdventureGraph.get_title(untitled)).is_equal("Untitled page")

func _adventure(starting_page: AdventurePage) -> Adventure:
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = starting_page
	return adventure

func _location(title: String, area: AdventureArea) -> AdventurePage:
	var page: AdventurePage = AdventurePage.new()
	page.title = title
	page.area = area
	return page

func _link(from: AdventurePage, to: AdventurePage) -> void:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.transition = to
	from.decisions.append(decision)
