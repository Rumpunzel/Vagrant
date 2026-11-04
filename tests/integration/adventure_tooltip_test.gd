extends GdUnitTestSuite

## The adventure editor's rich tooltips through tooltips_pro: hovering opens one with its text, and its links get tooltips of their own.

func after_test() -> void:
	TooltipManager.force_close_stack()
	await await_millis(200)

func test_hovering_opens_it_with_working_links() -> void:
	var shore: AdventureLocation = AdventureLocation.new()
	shore.title = "Shore"
	var ambush: AdventureEvent = AdventureEvent.new()
	ambush.title = "Ambush"
	TestAdventures.add(shore, ambush)
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = shore
	var card: Button = auto_free(Button.new())
	card.tooltip_text = "plain"
	add_child(card)
	AdventureTooltips.new(AdventureGraph.new(adventure)).attach(card, ambush)
	assert_str(card.tooltip_text).is_empty()
	card.mouse_entered.emit()
	var waited: int = 0
	while TooltipManager.mouse_tooltip_stack.is_empty() and waited < 2000:
		await await_millis(20)
		waited += 20
	assert_array(TooltipManager.mouse_tooltip_stack).has_size(1)
	var tooltip: AdventureTooltip = TooltipManager.mouse_tooltip_stack[0] as AdventureTooltip
	assert_object(tooltip).is_not_null()
	var label: RichTextLabel = tooltip.content_labels[0]
	assert_str(label.text).contains("[b]Ambush[/b]")
	assert_str(label.text).contains("[url=%d]" % shore.get_instance_id())
	assert_int(label.find_children("*", "", false, false).filter(func(node: Node) -> bool: return node is AdventureTooltipTrigger).size()).is_equal(1)
	# Locked after a moment: its links can be reached
	while tooltip.state != TooltipEnums.TooltipState.LOCKED and waited < 4000:
		await await_millis(20)
		waited += 20
	assert_int(label.mouse_filter).is_equal(Control.MOUSE_FILTER_PASS)
