extends GdUnitTestSuite

## Adventure pages and how their nested events change title, description, decisions, background and ambience.

class FalseCondition extends AdventureCondition:
	func is_true(_story: Story, _page: AdventurePage) -> bool: return false

var _story: Story

func before_test() -> void:
	_story = auto_free(Story.new())

func test_plain_page() -> void:
	var page: AdventurePage = _page("Ruin", "Damp.")
	assert_str(page.get_page_title(_story)).is_equal("Ruin")
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p]")
	assert_bool(page.are_all_prerequisites_fullfilled(_story)).is_true()

func test_title_includes_area() -> void:
	var page: AdventurePage = _page("Ruin", "")
	var area: AdventureArea = AdventureArea.new()
	area.name = "Swamp"
	page._area = area
	assert_str(page.get_page_title(_story)).is_equal("Swamp — Ruin")

func test_event_adds_to_description_and_decisions() -> void:
	var page: AdventurePage = _page("Ruin", "Damp.")
	var event: AdventurePage = _page("", "A hiss!")
	var base_decision: AdventureDecision = _decision("Leave")
	var event_decision: AdventureDecision = _decision("Fight")
	page._decisions = [base_decision] as Array[AdventureDecision]
	event._decisions = [event_decision] as Array[AdventureDecision]
	page._events = [event] as Array[AdventurePage]
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p][p]A hiss![/p]")
	assert_array(page.get_decisions(_story)).is_equal([event_decision, base_decision])
	assert_array(page.get_events(_story)).is_equal([event])

func test_event_title_overrides() -> void:
	var page: AdventurePage = _page("Ruin", "")
	page._events = [_page("Ambush", "")] as Array[AdventurePage]
	assert_str(page.get_page_title(_story)).is_equal("Ambush")

func test_event_with_false_condition_is_ignored() -> void:
	var page: AdventurePage = _page("Ruin", "Damp.")
	var event: AdventurePage = _page("Ambush", "A hiss!")
	event._conditions = [FalseCondition.new()] as Array[AdventureCondition]
	page._events = [event] as Array[AdventurePage]
	assert_str(page.get_page_title(_story)).is_equal("Ruin")
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p]")
	assert_array(page.get_events(_story)).is_empty()

func test_event_needs_all_conditions() -> void:
	var event: AdventurePage = _page("Ambush", "")
	event._conditions = [AdventureIsAlwaysTrueCondition.new(), FalseCondition.new()] as Array[AdventureCondition]
	assert_bool(event.are_all_prerequisites_fullfilled(_story)).is_false()
	event._conditions = [AdventureIsAlwaysTrueCondition.new(), AdventureIsAlwaysTrueCondition.new()] as Array[AdventureCondition]
	assert_bool(event.are_all_prerequisites_fullfilled(_story)).is_true()

func test_exclude_above_drops_earlier_events() -> void:
	var page: AdventurePage = _page("Ruin", "Damp.")
	var first: AdventurePage = _page("", "First.")
	var second: AdventurePage = _page("", "Second.")
	second._exclusivity = AdventurePage.Exclusivity.EXCLUDE_ABOVE
	page._events = [first, second] as Array[AdventurePage]
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p][p]Second.[/p]")
	assert_array(page.get_events(_story)).is_equal([second])

func test_exclude_below_stops_later_events() -> void:
	var page: AdventurePage = _page("Ruin", "Damp.")
	var first: AdventurePage = _page("", "First.")
	first._exclusivity = AdventurePage.Exclusivity.EXCLUDE_BELOW
	page._events = [first, _page("", "Second.")] as Array[AdventurePage]
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p][p]First.[/p]")
	assert_array(page.get_events(_story)).is_equal([first])

func test_exclude_base_and_below_hides_the_page_itself() -> void:
	var page: AdventurePage = _page("Ruin", "Damp.")
	page._decisions = [_decision("Leave")] as Array[AdventureDecision]
	var event: AdventurePage = _page("", "A hiss!")
	var event_decision: AdventureDecision = _decision("Fight")
	event._decisions = [event_decision] as Array[AdventureDecision]
	event._exclusivity = AdventurePage.Exclusivity.EXCLUDE_BASE | AdventurePage.Exclusivity.EXCLUDE_BELOW
	page._events = [event, _page("", "Second.")] as Array[AdventurePage]
	assert_str(page.get_description(_story)).is_equal("[p]A hiss![/p]")
	assert_array(page.get_decisions(_story)).is_equal([event_decision])

func test_exclude_base_alone_hides_the_page_itself() -> void:
	var page: AdventurePage = _page("Ruin", "Damp.")
	page._decisions = [_decision("Leave")] as Array[AdventureDecision]
	var event: AdventurePage = _page("", "A hiss!")
	event._exclusivity = AdventurePage.Exclusivity.EXCLUDE_BASE
	var second: AdventurePage = _page("", "Second.")
	page._events = [event, second] as Array[AdventurePage]
	# Later events still show, only the page's own part is gone
	assert_str(page.get_description(_story)).is_equal("[p]A hiss![/p][p]Second.[/p]")
	assert_array(page.get_decisions(_story)).is_empty()

func test_dropped_event_does_not_hide_base() -> void:
	var page: AdventurePage = _page("Ruin", "Damp.")
	var hiding: AdventurePage = _page("", "First.")
	hiding._exclusivity = AdventurePage.Exclusivity.EXCLUDE_BASE
	var dropping: AdventurePage = _page("", "Second.")
	dropping._exclusivity = AdventurePage.Exclusivity.EXCLUDE_ABOVE
	page._events = [hiding, dropping] as Array[AdventurePage]
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p][p]Second.[/p]")

func test_hide_all_shows_only_the_event() -> void:
	var page: AdventurePage = _page("Ruin", "Damp.")
	page._decisions = [_decision("Leave")] as Array[AdventureDecision]
	var event: AdventurePage = _page("", "A hiss!")
	var event_decision: AdventureDecision = _decision("Fight")
	event._decisions = [event_decision] as Array[AdventureDecision]
	event._exclusivity = 7
	page._events = [_page("", "Before."), event, _page("", "After.")] as Array[AdventurePage]
	assert_str(page.get_description(_story)).is_equal("[p]A hiss![/p]")
	assert_array(page.get_decisions(_story)).is_equal([event_decision])
	assert_array(page.get_events(_story)).is_equal([event])

func test_background_and_ambience_fallbacks() -> void:
	var page: AdventurePage = _page("Ruin", "")
	var area: AdventureArea = AdventureArea.new()
	area.background = PlaceholderTexture2D.new()
	area.ambience = AudioStreamGenerator.new()
	page._area = area
	assert_object(page.get_area_background()).is_same(area.background)
	assert_object(page.get_ambience(_story)).is_same(area.ambience)
	var event: AdventurePage = _page("", "")
	event._background = PlaceholderTexture2D.new()
	event._ambience = AudioStreamGenerator.new()
	page._events = [event] as Array[AdventurePage]
	assert_object(page.get_background(_story)).is_same(event._background)
	assert_object(page.get_ambience(_story)).is_same(event._ambience)

func test_transition_loads_its_page() -> void:
	var transition: AdventureTransition = AdventureTransition.new()
	transition._leads_to = "uid://ycd6xhx346l6"  # rocky_shore.tres
	assert_object(transition.get_adventure_page()).is_same(load("uid://ycd6xhx346l6"))
	var page: AdventurePage = _page("", "")
	assert_object(page.get_adventure_page()).is_same(page)

func _page(title: String, description: String) -> AdventurePage:
	var page: AdventurePage = AdventurePage.new()
	page._title = title
	page._description = description
	return page

func _decision(description: String) -> AdventureDecision:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.description = description
	return decision
