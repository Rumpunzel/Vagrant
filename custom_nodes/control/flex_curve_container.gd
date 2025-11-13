@tool
class_name FlexCurveContainer
extends FlexContainer

const _curve_container_name: StringName = "CurveContainer"

@export var _offset_curve: Curve

func add(element: Control) -> void:
	var curve_container: BoxContainer
	var curve_placeholder: Control = Control.new()
	curve_placeholder.name = "CurvePlaceholder"
	curve_placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match _direction:
		Direction.LEFT_TO_RIGHT, Direction.RIGHT_TO_LEFT:
			curve_container = VBoxContainer.new()
			if _fill: curve_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		Direction.TOP_TO_BOTTOM, Direction.BOTTOM_TO_TOP:
			curve_container = HBoxContainer.new()
			if _fill: curve_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_: assert(false, "Does not exist")
	curve_container.name = _curve_container_name
	curve_container.alignment = BoxContainer.ALIGNMENT_END	
	curve_container.add_theme_constant_override("separation", 0)
	curve_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	match _direction:
		Direction.LEFT_TO_RIGHT, Direction.TOP_TO_BOTTOM:
			curve_container.add_child(element)
			curve_container.add_child(curve_placeholder)
		Direction.RIGHT_TO_LEFT, Direction.BOTTOM_TO_TOP:
			curve_container.add_child(curve_placeholder)
			curve_container.add_child(element)
		_: assert(false, "Does not exist")
	super.add(curve_container)

func get_elements() -> Array[Control]:
	var curve_containers: Array[BoxContainer] = []
	curve_containers.assign(_box_container.get_children())
	var elements: Array[Control] = []
	match _direction:
		Direction.LEFT_TO_RIGHT, Direction.TOP_TO_BOTTOM:
			elements.assign(curve_containers.map(func(container: BoxContainer) -> Control: return container.get_child(0)))
		Direction.RIGHT_TO_LEFT, Direction.BOTTOM_TO_TOP:
			elements.assign(curve_containers.map(func(container: BoxContainer) -> Control: return container.get_child(1)))
		_: assert(false, "Does not exist")
	return elements

func _setup() -> void:
	if _box_container:
		_box_container.child_entered_tree.disconnect(_align_elements_on_curve)
		_box_container.child_order_changed.disconnect(_align_elements_on_curve)
	super._setup()
	_box_container.child_entered_tree.connect(_align_elements_on_curve.unbind(1))
	_box_container.child_order_changed.connect(_align_elements_on_curve)

func _align_elements_on_curve() -> void:
	var placeholders: Array[Control] = _get_curve_placeholders()
	for placeholder_index: int in placeholders.size():
		var placeholder: Control = placeholders[placeholder_index]
		var offset: float = _offset_curve.sample(placeholder_index)
		match _direction:
			Direction.LEFT_TO_RIGHT, Direction.RIGHT_TO_LEFT: placeholder.custom_minimum_size.y = offset
			Direction.TOP_TO_BOTTOM, Direction.BOTTOM_TO_TOP: placeholder.custom_minimum_size.x = offset
			_: assert(false, "Does not exist")

func _get_curve_placeholders() -> Array[Control]:
	var curve_containers: Array[BoxContainer] = []
	curve_containers.assign(_box_container.get_children())
	var placeholders: Array[Control] = []
	match _direction:
		Direction.LEFT_TO_RIGHT, Direction.TOP_TO_BOTTOM:
			placeholders.assign(curve_containers.map(func(container: BoxContainer) -> Control: return container.get_child(1)))
		Direction.RIGHT_TO_LEFT, Direction.BOTTOM_TO_TOP:
			placeholders.assign(curve_containers.map(func(container: BoxContainer) -> Control: return container.get_child(0)))
		_: assert(false, "Does not exist")
	return placeholders
