@tool
class_name FlexCurveContainer
extends FlexContainer

@export var offset_curve: Curve
@export var relative_offset: bool = true
@export var invert_offset: bool = false

func add(element: Control) -> void:
	var curve_container: MarginContainer = MarginContainer.new()
	curve_container.add_theme_constant_override("margin_left", 0)
	curve_container.add_theme_constant_override("margin_top", 0)
	curve_container.add_theme_constant_override("margin_right", 0)
	curve_container.add_theme_constant_override("margin_bottom", 0)
	curve_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match direction:
		Direction.LEFT_TO_RIGHT, Direction.RIGHT_TO_LEFT:
			if invert_offset: element.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			else: element.size_flags_vertical = Control.SIZE_SHRINK_END
		Direction.TOP_TO_BOTTOM, Direction.BOTTOM_TO_TOP:
			if invert_offset: element.size_flags_horizontal = Control.SIZE_SHRINK_END
			else: element.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		_: assert(false, "Does not exist")
	curve_container.add_child(element)
	super.add(curve_container)
	_align_elements_on_curve()

func get_elements() -> Array[Control]:
	var curve_containers: Array[MarginContainer] = []
	curve_containers.assign(_box_container.get_children())
	var elements: Array[Control] = []
	elements.assign(curve_containers.map(func(container: BoxContainer) -> Control: return container.get_child(0)))
	return elements

func _align_elements_on_curve() -> void:
	if not is_node_ready(): await ready
	await get_tree().process_frame
	var curve_containers: Array[MarginContainer] = _get_curve_containers()
	for container_index: int in curve_containers.size():
		var curve_container: MarginContainer = curve_containers[container_index]
		curve_container.add_theme_constant_override("margin_left", 0)
		curve_container.add_theme_constant_override("margin_top", 0)
		curve_container.add_theme_constant_override("margin_right", 0)
		curve_container.add_theme_constant_override("margin_bottom", 0)
		var offset: float = offset_curve.sample(container_index)
		if relative_offset: offset *= size.y
		match direction:
			Direction.LEFT_TO_RIGHT, Direction.RIGHT_TO_LEFT:
				if invert_offset: curve_container.add_theme_constant_override("margin_top", int(offset))
				else: curve_container.add_theme_constant_override("margin_bottom", int(offset))
			Direction.TOP_TO_BOTTOM, Direction.BOTTOM_TO_TOP:
				if invert_offset: curve_container.add_theme_constant_override("margin_right", int(offset))
				else: curve_container.add_theme_constant_override("margin_left", int(offset))
			_: assert(false, "Does not exist")

func _get_curve_containers() -> Array[MarginContainer]:
	var curve_containers: Array[MarginContainer] = []
	curve_containers.assign(_box_container.get_children())
	return curve_containers

func _set_box_container(new_box_container: BoxContainer) -> void:
	if false and _box_container:
		_box_container.child_entered_tree.disconnect(_align_elements_on_curve)
		_box_container.child_order_changed.disconnect(_align_elements_on_curve)
		_box_container.resized.disconnect(_align_elements_on_curve)
	super._set_box_container(new_box_container)
	return
	_box_container.child_entered_tree.connect(_align_elements_on_curve.unbind(1))
	_box_container.child_order_changed.connect(_align_elements_on_curve)
	_box_container.resized.connect(_align_elements_on_curve)
