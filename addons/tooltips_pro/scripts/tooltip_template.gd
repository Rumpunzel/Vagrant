@tool
class_name Tooltip
extends Control

## The TooltipTemplate defines the layout and appearance of tooltips.
##
## [b]TooltipTemplates[/b] must be located in the directory path assigned to [b]Tooltip
## Template Dir Path[/b] on the [b]Tooltip Settings[/b] resource. There should not be any
## Objects or Resources in the directory other than [b]TooltipTemplates[/b].
##[br][br]
## The first [code].tscn[/code] in the directory will be used as the default template, used
## when [b]Tooltip Template Path[/b] on a [TooltipTrigger] is empty.

## The [RichTextLabel]s have their text set by the [code]tooltip_strings[/code]
## on a [TooltipTrigger].
@export var content_labels: Array[RichTextLabel]
## UI elements that will [code]hide()[/code] when the tooltip is unlocked and
## [code]show()[/code] when locked.
@export var lock_elements: Array[Control]
## Vagrant: any [Range] (e.g. a [ProgressBar]), filled by the normalized time until the tooltip locks
## ([code]timer_lock_delay[/code])
@export var timer_lock_progress_bar: Range
## Vagrant: the widest a content label grows; longer lines wrap at it (0: they never wrap)
@export var max_width: float = 0.0

@export_group("Tweening")
## Use a tween scale animation from [code]Vector2.ZERO[/code] to [code]Vector2.ONE[/code]
## when the tooltip is created.
@export var use_tween_in: bool
## Tween's duration in seconds.
@export var tween_in_duration: float = 0.1
## Tween's EaseType.
@export var tween_in_ease_type: Tween.EaseType = Tween.EaseType.EASE_IN_OUT
## Create a "pop" effect by briefly increasing the scale past Vector2.ONE
@export var pop_scale: Vector2 = Vector2.ONE
## Use a tween scale animation from [code]Vector2.ONE[/code] to [code]Vector2.ZERO[/code]
## when the tooltip is removed.
@export var use_tween_out: bool
## Tween's duration in seconds.
@export var tween_out_duration: float = 0.1
## Tween's EaseType.
@export var tween_out_ease_type: Tween.EaseType = Tween.EaseType.EASE_IN_OUT

var trigger: TooltipTrigger
var child_trigger_nodes: Array[Node]
var tween: Tween
var state: TooltipEnums.TooltipState
var stack_coroutine_manager: TooltipStackCoroutineManager = TooltipStackCoroutineManager.new()
## Vagrant: locked or unlocked by hand (the lock input), which the lock timer then leaves alone
var _lock_toggled: bool = false

func _init(trigger_p: TooltipTrigger = null) -> void:
	trigger = trigger_p

	for element: Control in lock_elements:
		element.hide()

	if timer_lock_progress_bar:
		timer_lock_progress_bar.value = 0.0
		timer_lock_progress_bar.hide()

	child_trigger_nodes = self.find_children("*", "TooltipTrigger", true, false)

	state = TooltipEnums.TooltipState.READY


func init_lock_mode() -> void:
	match trigger.get_settings().lock_mode:
		TooltipEnums.TooltipLockMode.AUTO_LOCK:
			lock()
		TooltipEnums.TooltipLockMode.TIMER_LOCK:
			begin_lock_delay()


func toggle_lock() -> void:
	if trigger.get_settings().lock_mode == TooltipEnums.TooltipLockMode.NO_LOCK:
		return

	_lock_toggled = true
	match state:
		TooltipEnums.TooltipState.READY:
			lock()
		TooltipEnums.TooltipState.LOCKED:
			unlock()


func begin_lock_delay() -> void:
	var lock_delay: float = trigger.get_settings().timer_lock_delay

	if timer_lock_progress_bar:
		timer_lock_progress_bar.show()

	var t: float = 0.0
	while t < lock_delay and not _lock_toggled:
		t += get_process_delta_time()
		if timer_lock_progress_bar:
			timer_lock_progress_bar.value = 1.0 - (lock_delay - t) / lock_delay
		await get_tree().process_frame

	if not _lock_toggled: lock()


func lock() -> void:
	for element: Control in lock_elements:
		element.show()
	if timer_lock_progress_bar:
		timer_lock_progress_bar.hide()

	self.mouse_filter = Control.MOUSE_FILTER_STOP
	# Vagrant: the nested triggers are plain Nodes; it's their trigger_node that takes the mouse
	for child_trigger: TooltipTrigger in child_trigger_nodes:
		var control: Control = child_trigger.trigger_node as Control
		if control: control.mouse_filter = Control.MOUSE_FILTER_PASS

	state = TooltipEnums.TooltipState.LOCKED


func unlock() -> void:
	for element: Control in lock_elements:
		element.hide()

	self.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child_trigger: TooltipTrigger in child_trigger_nodes:
		var control: Control = child_trigger.trigger_node as Control
		if control: control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	state = TooltipEnums.TooltipState.READY


## Vagrant: the strings as they are; the placeholder substitution ([code]{name}[/code] → a variable) is gone, as it broke any text with braces
func set_content(tooltip_strings: Array[String]) -> void:
	for i: int in tooltip_strings.size():
		if content_labels.size() > i:
			content_labels[i].text = tooltip_strings[i]
			if max_width > 0.0: fit_width(content_labels[i], max_width)
		else:
			printerr(name, " has fewer RichTextLabels than there are content strings on trigger ", trigger.name)


## Vagrant: [param label] as wide as its widest line, but wrapping at [param max_width]. Measured with its font from the plain text (its
## tags taken out), as a label not yet laid out (or outside the tree) knows no width of its own
static func fit_width(label: RichTextLabel, max_width: float) -> void:
	var font: Font = label.get_theme_font("normal_font")
	var font_size: int = label.get_theme_font_size("normal_font_size")
	var plain: String = RegEx.create_from_string("\\[[^\\]]*\\]").sub(label.text, "", true)
	var widest: float = 0.0
	for line: String in plain.split("\n"): widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	var wraps: bool = widest > max_width
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wraps else TextServer.AUTOWRAP_OFF
	label.custom_minimum_size.x = max_width if wraps else 0.0


func set_pivot(_alignment: TooltipEnums.TooltipAlignment) -> void:
	match _alignment:
		TooltipEnums.TooltipAlignment.TOP_LEFT:
			self.pivot_offset = Vector2(self.size.x, self.size.y)
		TooltipEnums.TooltipAlignment.TOP_CENTER:
			self.pivot_offset = Vector2(self.size.x / 2, self.size.y)
		TooltipEnums.TooltipAlignment.TOP_RIGHT:
			self.pivot_offset = Vector2(0.0, self.size.y)
		TooltipEnums.TooltipAlignment.MIDDLE_LEFT:
			self.pivot_offset = Vector2(self.size.x, self.size.y / 2)
		TooltipEnums.TooltipAlignment.MIDDLE_CENTER:
			self.pivot_offset = Vector2(self.size.x / 2, self.size.y / 2)
		TooltipEnums.TooltipAlignment.MIDDLE_RIGHT:
			self.pivot_offset = Vector2(0.0, self.size.y / 2)
		TooltipEnums.TooltipAlignment.BOTTOM_LEFT:
			self.pivot_offset = Vector2(self.size.x, 0.0)
		TooltipEnums.TooltipAlignment.BOTTOM_CENTER:
			self.pivot_offset = Vector2(self.size.x / 2, 0.0)
		TooltipEnums.TooltipAlignment.BOTTOM_RIGHT:
			self.pivot_offset = Vector2(0.0, 0.0)
		_:
			self.pivot_offset = Vector2.ZERO


func set_stack_position_modulate(index: int) -> void:
	var settings: TooltipSettings = TooltipManager.tooltip_settings
	if index == 0:
		self.modulate = Color.WHITE
	elif index >= settings.darken_step_count:
		self.modulate = settings.step_limit_color
	else:
		var color_value: float = 1.0 - (settings.darken_step_value * (index + 1))
		self.modulate = Color(color_value, color_value, color_value, 1.0)


func tween_in() -> void:
	if not use_tween_in:
		return

	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0)
	tween.set_ease(tween_in_ease_type)
	tween.tween_property(self, "scale", pop_scale, tween_in_duration)
	if pop_scale != Vector2.ONE:
		tween.set_ease(Tween.EaseType.EASE_IN)
		tween.tween_property(self, "scale", Vector2.ONE, tween_in_duration)


func tween_out() -> void:
	if not use_tween_out:
		return

	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(tween_out_ease_type)
	tween.tween_property(self, "scale", Vector2.ZERO, tween_out_duration)
	await get_tree().create_timer(tween_out_duration).timeout


func _on_mouse_entered() -> void:
	stack_coroutine_manager.free_coroutines()
	match state:
		TooltipEnums.TooltipState.LOCKED:
			TooltipManager.collapse_tooltip_stack(TooltipManager.mouse_tooltip_stack.find(self))
		TooltipEnums.TooltipState.UNLOCKING:
			trigger.cancel_unlock_delay()


func _on_mouse_exited() -> void:
	stack_coroutine_manager.force_close_stack_run(self)
