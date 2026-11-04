extends GdUnitTestSuite

## Tooltips show in the window their trigger is in (popped-out character sheets and the debug panel), and links in a text get their own.

var _window: Window

func before_test() -> void:
	_window = auto_free(Window.new())
	_window.size = Vector2i(400, 300)
	add_child(_window)

func after_test() -> void:
	TooltipManager.force_close_stack()
	await await_millis(300)

func test_a_tooltip_shows_in_its_triggers_window() -> void:
	var control: Control = Control.new()
	_window.add_child(control)
	var trigger: TooltipTrigger = TooltipTrigger.new()
	trigger.trigger_node = control
	trigger.origin = TooltipEnums.TooltipOrigin.MOUSE_POSITION_FOLLOW
	trigger.tooltip_strings = ["Guts"] as Array[String]
	control.add_child(trigger)
	trigger.state = TooltipEnums.TriggerState.INIT_MOUSE_ENTERED
	var tooltip: Tooltip = await TooltipManager.init_tooltip(trigger, Vector2.ZERO)
	assert_object(tooltip.get_viewport()).is_same(_window)

func test_links_get_their_own_tooltips() -> void:
	var label: RichTextLabel = RichTextLabel.new()
	label.bbcode_enabled = true
	label.text = "[url=a]A[/url] [url=b]B[/url]"
	_window.add_child(label)
	var trigger: MetaTooltipTrigger = MetaTooltipTrigger.new()
	trigger.trigger_node = label
	trigger.origin = TooltipEnums.TooltipOrigin.MOUSE_POSITION_START
	trigger.tooltip_for = func(meta: Variant) -> Array[String]:
		var strings: Array[String] = []
		if meta == "a": strings.append("About a")
		return strings
	label.add_child(trigger)
	var open_delay: float = TooltipManager.tooltip_settings.open_delay
	var wait: int = int(open_delay * 1000.0) + 300
	# No tooltip for a link without one
	label.meta_hover_started.emit("b")
	await await_millis(wait)
	assert_object(trigger.active_tooltip).is_null()
	label.meta_hover_ended.emit("b")
	label.meta_hover_started.emit("a")
	await await_millis(wait)
	assert_object(trigger.active_tooltip).is_not_null()
	assert_array(trigger.tooltip_strings).contains_exactly(["About a"])
	assert_object(trigger.active_tooltip.get_viewport()).is_same(_window)
	label.meta_hover_ended.emit("a")
