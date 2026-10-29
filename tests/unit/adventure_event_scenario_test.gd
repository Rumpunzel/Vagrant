extends GdUnitTestSuite

## Event scenarios: a host shows at most one of their events, the first whose prerequisites are met, as if it were listed on the host.

class Switch extends AdventureCondition:
	var on: bool

	func _init(is_on: bool) -> void: on = is_on
	func is_true(_story: Story, _page: AdventurePage) -> bool: return on

var _story: Story
var _host: AdventurePage
var _scenario: AdventureEventScenario
var _first: AdventurePage
var _second: AdventurePage

func before_test() -> void:
	_story = auto_free(Story.new())
	_host = _page("Ruin", "Damp.")
	_host.decisions = [_decision("Leave")] as Array[AdventureDecision]
	_first = _page("Ambush", "A hiss!")
	_first.conditions = [Switch.new(true)] as Array[AdventureCondition]
	_second = _page("", "It lies still.")
	_second.decisions = [_decision("Kill it")] as Array[AdventureDecision]
	_scenario = AdventureEventScenario.new()
	_scenario.events = [_first, _second] as Array[AdventurePage]
	_host.events = [_scenario] as Array[AdventurePage]

func test_shows_the_first_event_whose_prerequisites_are_met() -> void:
	assert_object(_scenario.resolve_event(_story)).is_same(_first)
	assert_array(_host.get_events(_story)).contains_exactly([_first])
	assert_str(_host.get_page_title(_story)).is_equal("Ambush")
	assert_str(_host.get_description(_story)).is_equal("[p]Damp.[/p][p]A hiss![/p]")

func test_falls_through_to_the_next_event() -> void:
	(_first.conditions[0] as Switch).on = false
	assert_array(_host.get_events(_story)).contains_exactly([_second])
	assert_str(_host.get_description(_story)).is_equal("[p]Damp.[/p][p]It lies still.[/p]")
	assert_array(_host.get_decisions(_story).map(func(decision: AdventureDecision) -> String: return decision.description)).contains_exactly(["Kill it", "Leave"])

func test_shows_nothing_if_no_event_fits() -> void:
	(_first.conditions[0] as Switch).on = false
	_second.conditions = [Switch.new(false)] as Array[AdventureCondition]
	assert_object(_scenario.resolve_event(_story)).is_null()
	assert_array(_host.get_events(_story)).is_empty()
	assert_str(_host.get_description(_story)).is_equal("[p]Damp.[/p]")

func test_own_conditions_gate_the_whole_scenario() -> void:
	_scenario.conditions = [Switch.new(false)] as Array[AdventureCondition]
	assert_array(_host.get_events(_story)).is_empty()

func test_hide_flags_of_the_shown_event_act_on_the_host() -> void:
	_first.exclusivity = 7
	var later: AdventurePage = _page("", "Birds sing.")
	_host.events.append(later)
	assert_str(_host.get_description(_story)).is_equal("[p]A hiss![/p]")
	assert_array(_host.get_decisions(_story)).is_empty()
	(_first.conditions[0] as Switch).on = false
	assert_str(_host.get_description(_story)).is_equal("[p]Damp.[/p][p]It lies still.[/p][p]Birds sing.[/p]")

func test_nested_scenarios_resolve() -> void:
	var outer: AdventureEventScenario = AdventureEventScenario.new()
	var empty: AdventureEventScenario = AdventureEventScenario.new()
	outer.events = [empty, _scenario] as Array[AdventurePage]
	assert_object(outer.resolve_event(_story)).is_same(_first)

func test_decision_owner_is_the_event_inside() -> void:
	assert_object(_host.find_decision_owner(_second.decisions[0])).is_same(_second)

func test_host_reference_leads_to_the_story_host() -> void:
	var reference: AdventureHostReference = AdventureHostReference.new()
	assert_object(reference.get_adventure_page()).is_null()
	_story._host = _host
	assert_object(reference.resolve(_story)).is_same(_host)

func _page(title: String, description: String) -> AdventurePage:
	var page: AdventurePage = AdventurePage.new()
	page.title = title
	page.description = description
	return page

func _decision(description: String) -> AdventureDecision:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.description = description
	return decision
