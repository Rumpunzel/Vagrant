extends GdUnitTestSuite

## Tooltips Pro as changed by us: content is shown as it is, the game's own template is the default, nested triggers lock cleanly.

const GAME_TEMPLATE: String = "uid://lcxfnimgupdh"  # tooltip.tscn

var _button: Button
var _trigger: TooltipTrigger

func before_test() -> void:
	_button = auto_free(Button.new())
	add_child(_button)
	_trigger = TooltipTrigger.new()
	_trigger.trigger_node = _button
	_button.add_child(_trigger)

func after_test() -> void:
	TooltipManager.force_close_stack()
	await await_millis(300)

func test_braces_are_shown_as_they_are() -> void:
	var tooltip: Tooltip = TooltipManager.init_tooltip(_trigger, Vector2.ZERO)
	tooltip.set_content(["Stages: {\"lurker\": 2}, plain {name}"] as Array[String])
	assert_str(tooltip.content_labels[0].text).is_equal("Stages: {\"lurker\": 2}, plain {name}")

func test_the_game_template_is_the_default() -> void:
	var tooltip: Tooltip = TooltipManager.init_tooltip(_trigger, Vector2.ZERO)
	assert_str(tooltip.scene_file_path).is_equal(ResourceUID.uid_to_path(GAME_TEMPLATE))
	assert_str(tooltip.theme_type_variation).is_equal("TooltipPanel")

func test_locking_lets_the_mouse_reach_nested_triggers() -> void:
	var tooltip: Tooltip = TooltipManager.init_tooltip(_trigger, Vector2.ZERO)
	var link: Label = Label.new()
	link.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.add_child(link)
	var nested: TooltipTrigger = TooltipTrigger.new()
	nested.trigger_node = link
	link.add_child(nested)
	tooltip.child_trigger_nodes = [nested] as Array[Node]
	tooltip.lock()
	assert_int(link.mouse_filter).is_equal(Control.MOUSE_FILTER_PASS)
	tooltip.unlock()
	assert_int(link.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)

func test_the_lock_key_locks_before_the_timer_would() -> void:
	var tooltip: Tooltip = TooltipManager.init_tooltip(_trigger, Vector2.ZERO)
	await _press_lock_key()
	assert_int(tooltip.state).is_equal(TooltipEnums.TooltipState.LOCKED)

func test_unlocked_by_key_the_timer_leaves_it_unlocked() -> void:
	var tooltip: Tooltip = TooltipManager.init_tooltip(_trigger, Vector2.ZERO)
	await _press_lock_key()
	await _press_lock_key()
	await await_millis(int(TooltipManager.tooltip_settings.timer_lock_delay * 1000) + 300)
	assert_int(tooltip.state).is_equal(TooltipEnums.TooltipState.READY)

## As a key press arrives: an input event, handled before the next frame's processing
func _press_lock_key() -> void:
	for pressed: bool in [true, false]:
		var event: InputEventAction = InputEventAction.new()
		event.action = TooltipManager.LOCK_ACTION
		event.pressed = pressed
		Input.parse_input_event(event)
		await await_idle_frame()
		await await_idle_frame()

func test_positioning_uses_the_size_wrapping_text_ends_up_with() -> void:
	var rich: RichTooltipTrigger = RichTooltipTrigger.new()
	rich.trigger_node = _button
	rich.content = func() -> String: return ""
	_button.add_child(rich)
	var lines: Array[String] = []
	for index: int in 5: lines.append("A line of tooltip text long enough to wrap at the tooltip's width, number %d." % index)
	var tooltip: Tooltip = TooltipManager.init_tooltip(rich, Vector2.ZERO)
	tooltip.set_content(["\n".join(lines)] as Array[String])
	# Right away, while its size is still stale (as when it is first positioned)
	var at: Vector2 = TooltipManager.get_alignment_position(tooltip, TooltipEnums.TooltipAlignment.TOP_LEFT, rich.offset)
	assert_vector(at).is_equal(tooltip.position - tooltip.size - rich.offset)
