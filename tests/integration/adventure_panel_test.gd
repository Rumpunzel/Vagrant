extends GdUnitTestSuite

## The adventure editor's location panel and an event's settings, built for real: rows per section and event, the button groups, the
## settings above an event's graph.

func test_the_location_panel_lists_its_sections_and_events() -> void:
	var ruin: AdventureLocation = AdventureLocation.new()
	ruin.title = "Ruin"
	ruin.description = "Damp."
	var hiss: AdventureEvent = AdventureEvent.new()
	hiss.title = "Hiss"
	TestAdventures.add(ruin, hiss)
	var panel: AdventureLocationView = auto_free(AdventureLocationView.new())
	panel.setup()
	add_child(panel)
	var opened: Array[AdventureEvent] = [ ]
	panel.event_opened.connect(func(event: AdventureEvent, _host: AdventurePage) -> void: opened.append(event))
	panel.show_location(ruin, [ ] as Array[AdventureEncounter], [ruin] as Array[AdventurePage])
	assert_bool(panel.visible).is_true()
	assert_str(panel._text.text).is_equal("Damp.")
	var texts: Array = panel._rows.find_children("*", "Button", true, false).map(func(button: Button) -> String: return button.text)
	assert_array(texts).contains(["1 · Its own events", "Hiss"])
	var row: Button = panel._rows.find_children("*", "Button", true, false).filter(func(button: Button) -> bool: return button.text == "Hiss")[0]
	row.pressed.emit()
	assert_array(opened).contains_exactly([hiss])
	panel.show_location(null, [ ] as Array[AdventureEncounter], [ ] as Array[AdventurePage])
	assert_bool(panel.visible).is_false()

func test_a_choice_shows_every_option_and_reports_another() -> void:
	var picked: Array[int] = [ ]
	var row: HBoxContainer = auto_free(AdventureUi.choice("Text:", ["Adds", "Replaces", "Only its own"] as Array[String], 2, [ ] as Array[String], func(option: int) -> void: picked.append(option)))
	add_child(row)
	var options: Array[Node] = row.find_children("*", "Button", false, false)
	assert_int(options.size()).is_equal(3)
	assert_bool((options[2] as Button).button_pressed).is_true()
	(options[2] as Button).pressed.emit()
	(options[0] as Button).pressed.emit()
	assert_array(picked).contains_exactly([0])

func test_an_event_s_settings_above_its_graph() -> void:
	var ruin: AdventureLocation = AdventureLocation.new()
	ruin.title = "Ruin"
	var hiss: AdventureEvent = AdventureEvent.new()
	hiss.title = "Hiss"
	hiss.decisions_layering = AdventureEvent.Layering.ONLY_THIS
	hiss.no_rest = true
	TestAdventures.add(ruin, hiss)
	var view: AdventureEventView = auto_free(AdventureEventView.new())
	add_child(view)
	view.setup()
	view.show_event(hiss, ruin)
	var settings: Control = auto_free(view.make_settings())
	var pressed: Array = settings.find_children("*", "Button", true, false).filter(func(button: Button) -> bool: return button.button_pressed).map(func(button: Button) -> String: return button.text)
	assert_array(pressed).contains_exactly(["Adds", "Only its own", "No rest here"])
	var changes: Array[Array] = [ ]
	view.changes_requested.connect(func(requested: Array[Array], _action: String, _file: Resource) -> void: changes.append_array(requested))
	var replaces: Button = settings.find_children("*", "Button", true, false).filter(func(button: Button) -> bool: return button.text == "Replaces Ruin's")[0]
	replaces.pressed.emit()
	assert_array(changes).has_size(1)
	assert_object(changes[0][0]).is_same(hiss)
	assert_str(str(changes[0][1])).is_equal("text_layering")
	assert_int(changes[0][2]).is_equal(AdventureEvent.Layering.REPLACES_LOCATION)
	# The graph's node shows only the page now
	assert_array(view.find_children("*", "CheckBox", true, false)).is_empty()
