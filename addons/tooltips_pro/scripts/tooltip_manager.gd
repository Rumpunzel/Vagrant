@tool
extends Node

## The TooltipManager controls the instantiation and positioning of tooltips.
##
## The [Tooltip] stack is managed by this autoloaded singleton. It also listens
## for the [code]action_lock_input[/code] signal which toggles locking a tooltip.
## [br][br]
## Vagrant: in the game, the [code]lock_tooltip[/code] input action emits it (not in the editor, where it would fire while typing).
## [br][br]
## Tooltips with an [b]Origin[/b] set to the mouse will be instantiated as
## children of the [TooltipManager]. The necessary [CanvasLayer] and [Control]
## parents are created automatically.

signal action_lock_input

## Added to the project's input map when the plugin is enabled
const LOCK_ACTION: StringName = &"lock_tooltip"

## Vagrant: as lookups instead of matches (same mapping)
const FLIPPED_H: Dictionary[TooltipEnums.TooltipAlignment, TooltipEnums.TooltipAlignment] = {
	TooltipEnums.TooltipAlignment.TOP_LEFT: TooltipEnums.TooltipAlignment.TOP_RIGHT,
	TooltipEnums.TooltipAlignment.TOP_RIGHT: TooltipEnums.TooltipAlignment.TOP_LEFT,
	TooltipEnums.TooltipAlignment.MIDDLE_LEFT: TooltipEnums.TooltipAlignment.MIDDLE_RIGHT,
	TooltipEnums.TooltipAlignment.MIDDLE_RIGHT: TooltipEnums.TooltipAlignment.MIDDLE_LEFT,
	TooltipEnums.TooltipAlignment.BOTTOM_LEFT: TooltipEnums.TooltipAlignment.BOTTOM_RIGHT,
	TooltipEnums.TooltipAlignment.BOTTOM_RIGHT: TooltipEnums.TooltipAlignment.BOTTOM_LEFT,
}
const FLIPPED_V: Dictionary[TooltipEnums.TooltipAlignment, TooltipEnums.TooltipAlignment] = {
	TooltipEnums.TooltipAlignment.TOP_LEFT: TooltipEnums.TooltipAlignment.BOTTOM_LEFT,
	TooltipEnums.TooltipAlignment.TOP_CENTER: TooltipEnums.TooltipAlignment.BOTTOM_CENTER,
	TooltipEnums.TooltipAlignment.TOP_RIGHT: TooltipEnums.TooltipAlignment.BOTTOM_RIGHT,
	TooltipEnums.TooltipAlignment.BOTTOM_LEFT: TooltipEnums.TooltipAlignment.TOP_LEFT,
	TooltipEnums.TooltipAlignment.BOTTOM_CENTER: TooltipEnums.TooltipAlignment.TOP_CENTER,
	TooltipEnums.TooltipAlignment.BOTTOM_RIGHT: TooltipEnums.TooltipAlignment.TOP_RIGHT,
}

var tooltip_settings: TooltipSettings = preload("uid://fmex0mp7jdgn")  # tooltip_settings.tres

var tooltip_templates: Dictionary[String, PackedScene]

var mouse_tooltip_stack: Array[Tooltip]
var focus_tooltip_stack: Array[Tooltip]

var follow_mouse: bool
var is_collapsing_stack: bool

var mouse_tooltips_parent: Node
## Vagrant: the parent for mouse tooltips in each window (popped-out windows too), made when first needed
var _mouse_tooltips_parents: Dictionary[Viewport, Control] = {}

func _ready() -> void:
	action_lock_input.connect(on_action_lock_input)
	load_tooltip_templates()

	mouse_tooltips_parent = get_mouse_tooltips_parent(get_viewport())

## Vagrant: a tooltip shows in the window its trigger is in, not always in the main window
func get_mouse_tooltips_parent(viewport: Viewport) -> Control:
	var parent: Control = _mouse_tooltips_parents.get(viewport)
	if is_instance_valid(parent): return parent
	var canvas_layer: CanvasLayer = CanvasLayer.new()
	canvas_layer.layer = 128
	parent = Control.new()
	parent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas_layer.add_child(parent)
	if viewport == get_viewport(): add_child(canvas_layer)
	else: viewport.add_child(canvas_layer)
	_mouse_tooltips_parents[viewport] = parent
	return parent


func load_tooltip_templates() -> void:
	for resource: String in ResourceLoader.list_directory(tooltip_settings.tooltip_template_dir_path):
		tooltip_templates.set(tooltip_settings.tooltip_template_dir_path + resource, load(tooltip_settings.tooltip_template_dir_path + resource))


# Vagrant: every frame instead of on mouse motion in _input, which only gets the main window's input
func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() and InputMap.has_action(LOCK_ACTION) and Input.is_action_just_pressed(LOCK_ACTION):
		action_lock_input.emit()
	if not mouse_tooltip_stack or not follow_mouse:
		return
	if (
		mouse_tooltip_stack[0].state == TooltipEnums.TooltipState.LOCKED
		or mouse_tooltip_stack[0].state == TooltipEnums.TooltipState.UNLOCKING
	):
		return
	position_tooltip(mouse_tooltip_stack[0])


## Vagrant: in every lock mode but NO_LOCK (checked by [method Tooltip.toggle_lock]), so the key also locks a timer-locked tooltip early
func on_action_lock_input() -> void:
	if mouse_tooltip_stack.size() > 0:
		mouse_tooltip_stack[0].toggle_lock()

func init_tooltip(tooltip_trigger: TooltipTrigger, screen_pos: Vector2) -> Tooltip:
	# If the tooltip stack is in process of collapsing with a delay it can cause
	# this new tooltip to also be removed, so first force close all the tooltips.
	if is_collapsing_stack:
		is_collapsing_stack = false
		force_close_stack()

	# Instantiate tooltip and add to Tooltip Stack
	var template: PackedScene = tooltip_templates.values()[0]
	if tooltip_trigger.tooltip_template_path:
		# Vagrant: templates outside the template directory too (the adventure editor's), loaded when first used
		if not tooltip_templates.has(tooltip_trigger.tooltip_template_path) and ResourceLoader.exists(tooltip_trigger.tooltip_template_path):
			tooltip_templates[tooltip_trigger.tooltip_template_path] = load(tooltip_trigger.tooltip_template_path)
		if tooltip_templates.has(tooltip_trigger.tooltip_template_path):
			template = tooltip_templates[tooltip_trigger.tooltip_template_path]
		else:
			printerr("No Tooltip Template at path \"", tooltip_trigger.tooltip_template_path, "\" found. Using default template for Trigger ", tooltip_trigger.name, ".")
	var new_tooltip: Tooltip = template.instantiate()

	new_tooltip._init(tooltip_trigger)
	if tooltip_trigger.trigger_mode == TooltipEnums.TriggerMode.FOCUS_ONLY:
		focus_tooltip_stack.push_front(new_tooltip)
	else:
		mouse_tooltip_stack.push_front(new_tooltip)

	var parent: Node = get_mouse_tooltips_parent(tooltip_trigger.get_viewport())
	if tooltip_trigger.origin == TooltipEnums.TooltipOrigin.TRIGGER_ELEMENT:
		if screen_pos == Vector2.ZERO:
			parent = tooltip_trigger
	elif tooltip_trigger.origin == TooltipEnums.TooltipOrigin.REMOTE_ELEMENT:
		if tooltip_trigger.remote_element_node:
			parent = tooltip_trigger.remote_element_node
	elif (
			tooltip_trigger.origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_START
			or tooltip_trigger.origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_FOLLOW
	):
		if tooltip_trigger.state == TooltipEnums.TriggerState.INIT_FOCUS_ENTERED:
			parent = tooltip_trigger

	parent.add_child(new_tooltip)
	# Positioning needs to be deferred due to tooltip sizing and positioning
	# order of operations that I don't understand. Without it, tooltip Controls
	# may be sized incorrectly, with, for example, a greater height than the
	# minimum expected.
	call_deferred("position_tooltip", new_tooltip, screen_pos)

	new_tooltip.tween_in()

	new_tooltip.init_lock_mode()
	var stack: Array[Tooltip] = mouse_tooltip_stack.duplicate()
	for i: int in stack.size():
		stack[i].set_stack_position_modulate(i)

	return new_tooltip


func position_tooltip(tooltip: Tooltip, screen_pos: Vector2 = Vector2.ZERO) -> void:
	var offset: Vector2 = tooltip.trigger.offset

	# Position tooltip relative to origin element set on TooltipTrigger
	var origin: TooltipEnums.TooltipOrigin = tooltip.trigger.origin

	var mouse_position: Vector2 = Vector2.ZERO

	if origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_START or origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_FOLLOW:
		if (
			tooltip.trigger.state == TooltipEnums.TriggerState.INIT_MOUSE_ENTERED or
			tooltip.trigger.state == TooltipEnums.TriggerState.ACTIVE_MOUSE_ENTERED
		):
			mouse_position = tooltip.get_viewport().get_mouse_position()
			if origin == TooltipEnums.TooltipOrigin.MOUSE_POSITION_FOLLOW:
				follow_mouse = true

	tooltip.set_position(get_alignment_position(tooltip, tooltip.trigger.tooltip_alignment, offset) + screen_pos + mouse_position)
	var new_alignment: TooltipEnums.TooltipAlignment = tooltip.trigger.tooltip_alignment

	# Reposition tooltip if necessary based on selected OverflowMode
	if tooltip.trigger.overflow_mode != TooltipEnums.OverflowMode.OVERFLOW:
		new_alignment = _keep_in_bounds(tooltip, offset, mouse_position)

	tooltip.set_pivot(new_alignment)

## Moves [param tooltip] back into its overflow bounds as its trigger's overflow mode says; returns the alignment it ends up with
func _keep_in_bounds(tooltip: Tooltip, offset: Vector2, mouse_position: Vector2) -> TooltipEnums.TooltipAlignment:
	var alignment: TooltipEnums.TooltipAlignment = tooltip.trigger.tooltip_alignment
	var new_alignment: TooltipEnums.TooltipAlignment = alignment
	var bounds_rect: Rect2 = tooltip.get_viewport().get_visible_rect()
	var tooltip_global_rect: Rect2 = tooltip.get_global_rect()
	var clamped_position: Vector2 = tooltip_global_rect.position
	var left_overflow: bool = false
	var top_overflow: bool = false
	var right_overflow: bool = false
	var bottom_overflow: bool = false

	if tooltip.trigger.overflow_bounds == TooltipEnums.OverflowBounds.CONTROL_NODE_SIZE:
		if tooltip.trigger.overflow_element_node:
			bounds_rect = tooltip.trigger.overflow_element_node.get_global_rect()
		else:
			print_debug("Missing Overflow Control Node. Overflow Bounds will instead use Screen Size.")

	if bounds_rect.encloses(tooltip_global_rect):
		return new_alignment

	var tooltip_end: Vector2 = tooltip_global_rect.end
	if alignment in [TooltipEnums.TooltipAlignment.TOP_LEFT, TooltipEnums.TooltipAlignment.MIDDLE_LEFT, TooltipEnums.TooltipAlignment.BOTTOM_LEFT, TooltipEnums.TooltipAlignment.BOTTOM_CENTER, TooltipEnums.TooltipAlignment.TOP_CENTER]:
		if tooltip_global_rect.position.x < bounds_rect.position.x:
			clamped_position.x = bounds_rect.position.x
			left_overflow = true
	if alignment in [TooltipEnums.TooltipAlignment.TOP_LEFT, TooltipEnums.TooltipAlignment.TOP_CENTER, TooltipEnums.TooltipAlignment.TOP_RIGHT, TooltipEnums.TooltipAlignment.MIDDLE_LEFT, TooltipEnums.TooltipAlignment.MIDDLE_RIGHT]:
		if tooltip_global_rect.position.y < bounds_rect.position.y:
			clamped_position.y = bounds_rect.position.y
			top_overflow = true
	if alignment in [TooltipEnums.TooltipAlignment.TOP_RIGHT, TooltipEnums.TooltipAlignment.MIDDLE_RIGHT, TooltipEnums.TooltipAlignment.BOTTOM_RIGHT, TooltipEnums.TooltipAlignment.BOTTOM_CENTER, TooltipEnums.TooltipAlignment.TOP_CENTER]:
		if tooltip_end.x > bounds_rect.end.x:
			clamped_position.x -= tooltip_end.x - bounds_rect.end.x
			right_overflow = true
	if alignment in [TooltipEnums.TooltipAlignment.BOTTOM_LEFT, TooltipEnums.TooltipAlignment.BOTTOM_CENTER, TooltipEnums.TooltipAlignment.BOTTOM_RIGHT, TooltipEnums.TooltipAlignment.MIDDLE_LEFT, TooltipEnums.TooltipAlignment.MIDDLE_RIGHT]:
		if tooltip_end.y > bounds_rect.end.y:
			clamped_position.y -= tooltip_end.y - bounds_rect.end.y
			bottom_overflow = true

	if tooltip.trigger.overflow_mode == TooltipEnums.OverflowMode.CLAMP:
		tooltip.set_global_position(clamped_position, false)
	elif tooltip.trigger.overflow_mode == TooltipEnums.OverflowMode.FLIPPED_ALIGNMENT:
		var flipped_h_alignment: TooltipEnums.TooltipAlignment = get_flipped_h_alignment(alignment)
		var flipped_v_alignment: TooltipEnums.TooltipAlignment = get_flipped_v_alignment(alignment)

		if left_overflow or right_overflow:
			tooltip.set_position(get_alignment_position(tooltip, flipped_h_alignment, offset) + mouse_position)
			new_alignment = flipped_h_alignment

			if not bounds_rect.encloses(tooltip.get_global_rect()):
				flipped_v_alignment = get_flipped_v_alignment(flipped_h_alignment)
				tooltip.set_position(get_alignment_position(tooltip, flipped_v_alignment, offset) + mouse_position)
				new_alignment = flipped_v_alignment

		if top_overflow or bottom_overflow:
			tooltip.set_position(get_alignment_position(tooltip, flipped_v_alignment, offset) + mouse_position)
			new_alignment = flipped_v_alignment

			if not bounds_rect.encloses(tooltip.get_global_rect()):
				flipped_h_alignment = get_flipped_h_alignment(flipped_v_alignment)
				tooltip.set_position(get_alignment_position(tooltip, flipped_h_alignment, offset) + mouse_position)
				new_alignment = flipped_h_alignment
	return new_alignment

## Sets the tooltip's anchors and grow directions for [param alignment] and returns its position relative to the TooltipTrigger node
func get_alignment_position(tooltip: Tooltip, alignment: TooltipEnums.TooltipAlignment, offset: Vector2) -> Vector2:
	var preset: Control.LayoutPreset = Control.LayoutPreset.PRESET_TOP_LEFT
	var grow_horizontal: Control.GrowDirection = Control.GROW_DIRECTION_BEGIN
	var grow_vertical: Control.GrowDirection = Control.GROW_DIRECTION_BEGIN
	# How the shift is made of the tooltip's size and the offset: (size.x, offset.x, size.y, offset.y)
	var factors: Vector4 = Vector4(-1, -1, -1, -1)
	match alignment:
		TooltipEnums.TooltipAlignment.TOP_CENTER:
			preset = Control.LayoutPreset.PRESET_CENTER_TOP
			grow_horizontal = Control.GROW_DIRECTION_BOTH
			factors = Vector4(0, -1, -1, -1)
		TooltipEnums.TooltipAlignment.TOP_RIGHT:
			preset = Control.LayoutPreset.PRESET_TOP_RIGHT
			grow_horizontal = Control.GROW_DIRECTION_END
			factors = Vector4(1, 1, -1, -1)
		TooltipEnums.TooltipAlignment.MIDDLE_LEFT:
			preset = Control.LayoutPreset.PRESET_CENTER_LEFT
			grow_vertical = Control.GROW_DIRECTION_BOTH
			factors = Vector4(-1, -1, 0, -1)
		TooltipEnums.TooltipAlignment.MIDDLE_CENTER:
			preset = Control.LayoutPreset.PRESET_FULL_RECT
			grow_horizontal = Control.GROW_DIRECTION_BOTH
			grow_vertical = Control.GROW_DIRECTION_BOTH
			factors = Vector4(0, 1, 0, -1)
		TooltipEnums.TooltipAlignment.MIDDLE_RIGHT:
			preset = Control.LayoutPreset.PRESET_CENTER_RIGHT
			grow_horizontal = Control.GROW_DIRECTION_END
			grow_vertical = Control.GROW_DIRECTION_BOTH
			factors = Vector4(1, 1, 0, -1)
		TooltipEnums.TooltipAlignment.BOTTOM_LEFT:
			preset = Control.LayoutPreset.PRESET_BOTTOM_LEFT
			grow_vertical = Control.GROW_DIRECTION_END
			factors = Vector4(-1, -1, 1, 1)
		TooltipEnums.TooltipAlignment.BOTTOM_CENTER:
			preset = Control.LayoutPreset.PRESET_CENTER_BOTTOM
			grow_horizontal = Control.GROW_DIRECTION_BOTH
			grow_vertical = Control.GROW_DIRECTION_END
			factors = Vector4(0, -1, 1, 1)
		TooltipEnums.TooltipAlignment.BOTTOM_RIGHT:
			preset = Control.LayoutPreset.PRESET_BOTTOM_RIGHT
			grow_horizontal = Control.GROW_DIRECTION_END
			grow_vertical = Control.GROW_DIRECTION_END
			factors = Vector4(1, 1, 1, 1)
	tooltip.set_anchors_and_offsets_preset(preset, Control.LayoutPresetMode.PRESET_MODE_KEEP_SIZE)
	tooltip.grow_horizontal = grow_horizontal
	tooltip.grow_vertical = grow_vertical
	# Read only now, as setting the anchors lets a tooltip whose text wraps take its real height (before, it can be far too tall)
	var size: Vector2 = tooltip.size
	return tooltip.position + Vector2(factors.x * size.x + factors.y * offset.x, factors.z * size.y + factors.w * offset.y)


func get_flipped_h_alignment(_old_alignment: TooltipEnums.TooltipAlignment) -> TooltipEnums.TooltipAlignment:
	return FLIPPED_H.get(_old_alignment, _old_alignment)


func get_flipped_v_alignment(_old_alignment: TooltipEnums.TooltipAlignment) -> TooltipEnums.TooltipAlignment:
	return FLIPPED_V.get(_old_alignment, _old_alignment)

func collapse_tooltip_stack(index: int = -1, collapse_focus_stack: bool = false) -> void:
	if is_collapsing_stack:
		return
	is_collapsing_stack = true

	var stack: Array[Tooltip] = focus_tooltip_stack.duplicate() if collapse_focus_stack else mouse_tooltip_stack.duplicate()

	if stack.size() == 0:
		is_collapsing_stack = false
		return

	var size_to_stop: int = stack.size() - clampi(index, 0, stack.size())
	if index == -1:
		size_to_stop = 0
	if stack[0].state != TooltipEnums.TooltipState.LOCKED:
		size_to_stop -= 1
	size_to_stop = clampi(size_to_stop, 0, stack.size())
	while stack.size() > size_to_stop and is_collapsing_stack:
		if stack[0] == null:
			break

		if stack[0].state == TooltipEnums.TooltipState.LOCKED:
			stack[0].state = TooltipEnums.TooltipState.UNLOCKING
			await get_tree().create_timer(stack[0].trigger.get_settings().unlock_delay).timeout

		if stack[0] == null:
			break

		if stack.size() > size_to_stop and is_collapsing_stack:
			remove_tooltip(stack[0])
			stack.remove_at(0)

		await get_tree().process_frame

	is_collapsing_stack = false


func force_close_stack() -> void:
	is_collapsing_stack = false
	for tooltip: Tooltip in mouse_tooltip_stack.duplicate():
		remove_tooltip(tooltip, false)

func remove_tooltip(tooltip: Tooltip, modulate: bool = true) -> void:
	tooltip.trigger.on_tooltip_removed()
	var stack: Array[Tooltip] = focus_tooltip_stack if tooltip.trigger.trigger_mode == TooltipEnums.TriggerMode.FOCUS_ONLY else mouse_tooltip_stack
	stack.erase(tooltip)
	if stack.size() == 0:
		is_collapsing_stack = false
	if modulate:
		for i: int in stack.size():
			stack[i].set_stack_position_modulate(i)

	await tooltip.tween_out()

	tooltip.queue_free()

	follow_mouse = false
