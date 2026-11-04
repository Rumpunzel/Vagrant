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

func test_an_event_replacing_the_location_s_text() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	page.decisions = [_decision("Leave")] as Array[AdventureDecision]
	var burning: AdventureEvent = _event("", "The temple burns.")
	burning.text_layering = AdventureEvent.Layering.REPLACES_LOCATION
	TestAdventures.list(page, [burning, _event("", "Birds sing.")] as Array[AdventureEvent])
	assert_str(page.get_description(_story)).is_equal("[p]The temple burns.[/p][p]Birds sing.[/p]")
	assert_int(page.get_decisions(_story).size()).is_equal(1)

func test_only_its_decisions_keeps_all_text() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	page.decisions = [_decision("Leave")] as Array[AdventureDecision]
	var ripples: AdventureEvent = _event("", "The water stirs.")
	var go_on: AdventureDecision = _decision("Continue")
	ripples.decisions = [go_on] as Array[AdventureDecision]
	ripples.decisions_layering = AdventureEvent.Layering.ONLY_THIS
	var birds: AdventureEvent = _event("", "Birds sing.")
	birds.decisions = [_decision("Listen")] as Array[AdventureDecision]
	TestAdventures.list(page, [birds, ripples] as Array[AdventureEvent])
	# You see everything, but can only react
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p][p]Birds sing.[/p][p]The water stirs.[/p]")
	assert_array(page.get_decisions(_story)).is_equal([go_on])

func test_only_its_text_and_decisions() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	page.decisions = [_decision("Leave")] as Array[AdventureDecision]
	var event: AdventureEvent = _event("", "A hiss!")
	var event_decision: AdventureDecision = _decision("Fight")
	event.decisions = [event_decision] as Array[AdventureDecision]
	event.text_layering = AdventureEvent.Layering.ONLY_THIS
	event.decisions_layering = AdventureEvent.Layering.ONLY_THIS
	TestAdventures.list(page, [_event("", "Before."), event, _event("", "After.")] as Array[AdventureEvent])
	assert_str(page.get_description(_story)).is_equal("[p]A hiss![/p]")
	assert_array(page.get_decisions(_story)).is_equal([event_decision])

func test_of_two_wanting_to_be_the_only_one_the_earlier_wins() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	var first: AdventureEvent = _event("", "First.")
	first.decisions_layering = AdventureEvent.Layering.ONLY_THIS
	var second: AdventureEvent = _event("", "Second.")
	second.decisions_layering = AdventureEvent.Layering.ONLY_THIS
	var third: AdventureEvent = _event("", "Third.")
	TestAdventures.list(page, [first, second, third] as Array[AdventureEvent])
	assert_array(page.get_events(_story)).is_equal([first, third])
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p][p]First.[/p][p]Third.[/p]")

func test_the_area_s_text_on_entering_it() -> void:
	var swamp: AdventureArea = AdventureArea.new()
	swamp.description = "Mist hangs over the reeds."
	swamp.first_description = "You have never smelled rot like this."
	var page: AdventureLocation = _location("Ruin", "Damp.")
	page.area = swamp
	_story._entered_area = swamp
	_story._first_time_in_area = true
	assert_str(page.get_description(_story)).is_equal("[p]You have never smelled rot like this.[/p][p]Damp.[/p]")
	_story._first_time_in_area = false
	assert_str(page.get_description(_story)).is_equal("[p]Mist hangs over the reeds.[/p][p]Damp.[/p]")
	# Arriving from within the area: no area text
	_story._entered_area = null
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p]")
	# Only this event's text: not even the area's
	var hiss: AdventureEvent = _event("", "A hiss!")
	hiss.text_layering = AdventureEvent.Layering.ONLY_THIS
	TestAdventures.list(page, [hiss] as Array[AdventureEvent])
	_story._entered_area = swamp
	assert_str(page.get_description(_story)).is_equal("[p]A hiss![/p]")

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

func test_first_visit_text() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	page.first_description = "You have never seen it before."
	assert_str(page.get_description(_story)).is_equal("[p]You have never seen it before.[/p]")
	_story.journal.enter(page)
	assert_str(page.get_description(_story)).is_equal("[p]Damp.[/p]")

func test_transition_loads_its_page() -> void:
	var transition: AdventureTransition = AdventureTransition.new()
	transition._leads_to = "uid://ycd6xhx346l6"  # rocky_shore.tres
	assert_object(transition.get_adventure_page()).is_same(load("uid://ycd6xhx346l6"))
	var page: AdventureLocation = _location("", "")
	assert_object(page.get_adventure_page()).is_same(page)

func test_no_rest_on_the_page_or_from_an_event_on_it() -> void:
	var page: AdventureLocation = _location("Ruin", "Damp.")
	assert_bool(page.forbids_rest(_story)).is_false()
	var eleanor: AdventureEvent = _event("", "A woman knocks at the gate.")
	eleanor.no_rest = true
	TestAdventures.list(page, [eleanor] as Array[AdventureEvent])
	assert_bool(page.forbids_rest(_story)).is_true()
	var burning: AdventurePage = AdventurePage.new()
	burning.no_rest = true
	assert_bool(burning.forbids_rest(_story)).is_true()

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
