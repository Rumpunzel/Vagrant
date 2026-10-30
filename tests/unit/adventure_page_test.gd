extends GdUnitTestSuite

## Adventure pages, and how a location's events change title, description, decisions, background and ambience.

class FalseCondition extends AdventureCondition:
	func is_true(_story: Story, _page: AdventurePage) -> bool: return false

var _story: Story

func before_test() -> void:
	_story = auto_free(Story.new())

func test_plain_page() -> void:
	var page: AdventurePage = AdventurePage.new()
	page.title = "Ruin"
	page.description = "Damp."
	assert_str(page.get_page_title(_story)).is_equal("Ruin")
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p]")
	assert_array(page.get_events(_story)).is_empty()

func test_location_without_events() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	assert_str(page.get_page_title(_story)).is_equal("Ruin")
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p]")
	assert_bool(_event("", "").are_all_prerequisites_fullfilled(_story)).is_true()

func test_title_includes_area() -> void:
	var page: AdventureLocation = _location("Ruin", "")
	var area: AdventureArea = AdventureArea.new()
	area.name = "Swamp"
	page.area = area
	assert_str(page.get_page_title(_story)).is_equal("Swamp — Ruin")

func test_event_adds_to_description_and_decisions() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	var event: AdventureEvent = _event("", "A hiss!")
	var base_decision: AdventureDecision = _decision("Leave")
	var event_decision: AdventureDecision = _decision("Fight")
	page.decisions = [base_decision] as Array[AdventureDecision]
	event.decisions = [event_decision] as Array[AdventureDecision]
	TestAdventures.list(page, [event] as Array[AdventureEvent])
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p][p]A hiss![/p]")
	assert_array(page.get_decisions(_story)).is_equal([event_decision, base_decision])
	assert_array(page.get_events(_story)).is_equal([event])

func test_event_title_overrides() -> void:
	var page: AdventureLocation = _location("Ruin", "")
	TestAdventures.list(page, [_event("Ambush", "")] as Array[AdventureEvent])
	assert_str(page.get_page_title(_story)).is_equal("Ambush")

func test_event_with_false_condition_is_ignored() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	var event: AdventureEvent = _event("Ambush", "A hiss!")
	event.conditions = [FalseCondition.new()] as Array[AdventureCondition]
	TestAdventures.list(page, [event] as Array[AdventureEvent])
	assert_str(page.get_page_title(_story)).is_equal("Ruin")
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p]")
	assert_array(page.get_events(_story)).is_empty()

func test_event_needs_all_conditions() -> void:
	var event: AdventureEvent = _event("Ambush", "")
	event.conditions = [AdventureIsAlwaysTrueCondition.new(), FalseCondition.new()] as Array[AdventureCondition]
	assert_bool(event.are_all_prerequisites_fullfilled(_story)).is_false()
	event.conditions = [AdventureIsAlwaysTrueCondition.new(), AdventureIsAlwaysTrueCondition.new()] as Array[AdventureCondition]
	assert_bool(event.are_all_prerequisites_fullfilled(_story)).is_true()

func test_exclude_above_drops_earlier_events() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	var first: AdventureEvent = _event("", "First.")
	var second: AdventureEvent = _event("", "Second.")
	second.exclusivity = AdventureEvent.Exclusivity.EXCLUDE_ABOVE
	TestAdventures.list(page, [first, second] as Array[AdventureEvent])
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p][p]Second.[/p]")
	assert_array(page.get_events(_story)).is_equal([second])

func test_exclude_below_stops_later_events() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	var first: AdventureEvent = _event("", "First.")
	first.exclusivity = AdventureEvent.Exclusivity.EXCLUDE_BELOW
	TestAdventures.list(page, [first, _event("", "Second.")] as Array[AdventureEvent])
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p][p]First.[/p]")
	assert_array(page.get_events(_story)).is_equal([first])

func test_exclude_base_and_below_hides_the_page_itself() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	page.decisions = [_decision("Leave")] as Array[AdventureDecision]
	var event: AdventureEvent = _event("", "A hiss!")
	var event_decision: AdventureDecision = _decision("Fight")
	event.decisions = [event_decision] as Array[AdventureDecision]
	event.exclusivity = AdventureEvent.Exclusivity.EXCLUDE_BASE | AdventureEvent.Exclusivity.EXCLUDE_BELOW
	TestAdventures.list(page, [event, _event("", "Second.")] as Array[AdventureEvent])
	assert_str(page.get_description(_story)).is_equal("[p]A hiss![/p]")
	assert_array(page.get_decisions(_story)).is_equal([event_decision])

func test_exclude_base_alone_hides_the_page_itself() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	page.decisions = [_decision("Leave")] as Array[AdventureDecision]
	var event: AdventureEvent = _event("", "A hiss!")
	event.exclusivity = AdventureEvent.Exclusivity.EXCLUDE_BASE
	var second: AdventureEvent = _event("", "Second.")
	TestAdventures.list(page, [event, second] as Array[AdventureEvent])
	# Later events still show, only the page's own part is gone
	assert_str(page.get_description(_story)).is_equal("[p]A hiss![/p][p]Second.[/p]")
	assert_array(page.get_decisions(_story)).is_empty()

func test_dropped_event_does_not_hide_base() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	var hiding: AdventureEvent = _event("", "First.")
	hiding.exclusivity = AdventureEvent.Exclusivity.EXCLUDE_BASE
	var dropping: AdventureEvent = _event("", "Second.")
	dropping.exclusivity = AdventureEvent.Exclusivity.EXCLUDE_ABOVE
	TestAdventures.list(page, [hiding, dropping] as Array[AdventureEvent])
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p][p]Second.[/p]")

func test_hide_all_shows_only_the_event() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	page.decisions = [_decision("Leave")] as Array[AdventureDecision]
	var event: AdventureEvent = _event("", "A hiss!")
	var event_decision: AdventureDecision = _decision("Fight")
	event.decisions = [event_decision] as Array[AdventureDecision]
	event.exclusivity = 7
	TestAdventures.list(page, [_event("", "Before."), event, _event("", "After.")] as Array[AdventureEvent])
	assert_str(page.get_description(_story)).is_equal("[p]A hiss![/p]")
	assert_array(page.get_decisions(_story)).is_equal([event_decision])
	assert_array(page.get_events(_story)).is_equal([event])

func test_background_and_ambience_fallbacks() -> void:
	var page: AdventureLocation = _location("Ruin", "")
	var area: AdventureArea = AdventureArea.new()
	area.background = PlaceholderTexture2D.new()
	area.ambience = AudioStreamGenerator.new()
	page.area = area
	assert_object(page.get_area_background()).is_same(area.background)
	assert_object(page.get_ambience(_story)).is_same(area.ambience)
	var event: AdventureEvent = _event("", "")
	event.background = PlaceholderTexture2D.new()
	event.ambience = AudioStreamGenerator.new()
	TestAdventures.list(page, [event] as Array[AdventureEvent])
	assert_object(page.get_background(_story)).is_same(event.background)
	assert_object(page.get_ambience(_story)).is_same(event.ambience)

func test_transition_loads_its_page() -> void:
	var transition: AdventureTransition = AdventureTransition.new()
	transition._leads_to = "uid://ycd6xhx346l6"  # rocky_shore.tres
	assert_object(transition.get_adventure_page()).is_same(load("uid://ycd6xhx346l6"))
	var page: AdventureLocation = _location("", "")
	assert_object(page.get_adventure_page()).is_same(page)

func _location(title: String, description: String) -> AdventureLocation:
	var location: AdventureLocation = AdventureLocation.new()
	location.title = title
	location.description = description
	return location

func _event(title: String, description: String) -> AdventureEvent:
	var event: AdventureEvent = AdventureEvent.new()
	event.title = title
	event.description = description
	return event

func _decision(description: String) -> AdventureDecision:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.description = description
	return decision
