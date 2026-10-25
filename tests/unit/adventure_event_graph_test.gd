extends GdUnitTestSuite

## The adventure editor's view of one event: the pages behind it, its exits and one outlet per decision outcome.

func test_walks_the_pages_behind_the_event() -> void:
	var ambush: AdventurePage = _page("Ambush", null)
	var won: AdventurePage = _page("Won", null)
	var deeper: AdventurePage = _page("Deeper", null)
	_link(ambush, won, "Fight")
	_link(won, deeper, "Go on")
	var graph: AdventureEventGraph = AdventureEventGraph.new(ambush)
	assert_object(graph.event).is_same(ambush)
	assert_array(graph.pages).contains_exactly([ambush, won, deeper])
	assert_array(graph.exits).is_empty()
	assert_int(graph.depths[deeper]).is_equal(2)

func test_locations_are_exits_and_not_walked() -> void:
	var ambush: AdventurePage = _page("Ambush", null)
	var temple: AdventurePage = _page("Temple", AdventureArea.new())
	_link(ambush, temple, "Leave")
	_link(temple, _page("Beyond", null), "Further")
	var graph: AdventureEventGraph = AdventureEventGraph.new(ambush)
	assert_array(graph.pages).contains_exactly([ambush])
	assert_array(graph.exits).contains_exactly([temple])
	assert_int(graph.depths[temple]).is_equal(1)

func test_nested_events_are_not_walked() -> void:
	var ambush: AdventurePage = _page("Ambush", null)
	var nested: AdventurePage = _page("Nested", null)
	ambush.events.append(nested)
	_link(nested, _page("Behind", null), "Go")
	assert_array(AdventureEventGraph.new(ambush).pages).contains_exactly([ambush])

func test_loops_end() -> void:
	var ambush: AdventurePage = _page("Ambush", null)
	var lost: AdventurePage = _page("Lost", null)
	_link(ambush, lost, "Fight")
	_link(lost, ambush, "Again")
	assert_array(AdventureEventGraph.new(ambush).pages).contains_exactly([ambush, lost])

func test_outlets_per_outcome() -> void:
	var ambush: AdventurePage = _page("Ambush", null)
	var won: AdventurePage = _page("Won", null)
	var lost: AdventurePage = _page("Lost", null)
	var fled: AdventurePage = _page("Fled", null)
	var fight: AdventureFightDecision = AdventureFightDecision.new()
	fight.description = "Fight!\nIt hisses."
	fight.transition = won
	fight.failure_transition = lost
	fight.flee_transition = fled
	var back: AdventureDecision = AdventureDecision.new()
	back.description = "Sneak away"
	ambush.decisions.append(fight)
	ambush.decisions.append(back)
	var outlets: Array[AdventureEventGraph.Outlet] = AdventureEventGraph.get_outlets(ambush)
	var labels: Array[String] = [ ]
	for outlet: AdventureEventGraph.Outlet in outlets: labels.append(outlet.label)
	assert_array(labels).contains_exactly_in_any_order(["Fight!", "↳ Failure", "↳ Flee", "Sneak away (back)"])
	assert_object(outlets[0].target).is_same(won)
	assert_object(outlets[labels.find("Sneak away (back)")].target).is_null()

func _page(title: String, area: AdventureArea) -> AdventurePage:
	var page: AdventurePage = AdventurePage.new()
	page.title = title
	page.area = area
	return page

func _link(from: AdventurePage, to: AdventurePage, description: String) -> void:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.description = description
	decision.transition = to
	from.decisions.append(decision)
