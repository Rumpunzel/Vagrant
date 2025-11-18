@tool
class_name FlexContainer
extends MarginContainer

enum Direction {
	LEFT_TO_RIGHT,
	RIGHT_TO_LEFT,
	TOP_TO_BOTTOM,
	BOTTOM_TO_TOP,
}

@export_range(0.0, 256.0, 1.0, "exp", "suffix:px") var element_size: float = 0.0
@export_range(-64, 64, 1, "suffix:px") var separation: int = 4
@export var fill: bool = true
@export var container_root: Control
@export var container_index_in_root: int = -1
@export var alignment: BoxContainer.AlignmentMode = BoxContainer.AlignmentMode.ALIGNMENT_BEGIN
@export var direction: Direction = Direction.LEFT_TO_RIGHT:
	set(new_direction):
		if new_direction == direction: return
		direction = new_direction
		if not is_node_ready(): return
		_setup()

var _box_container: BoxContainer : set = _set_box_container

func add(element: Control) -> void:
	assert(element)
	if not _box_container: _setup()
	assert(_box_container)
	if element_size > 0.0: element.custom_minimum_size = Vector2(element_size, element_size)
	if fill:
		match direction:
			Direction.LEFT_TO_RIGHT, Direction.RIGHT_TO_LEFT: element.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			Direction.TOP_TO_BOTTOM, Direction.BOTTOM_TO_TOP: element.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_: assert(false, "Does not exist")
	_box_container.add_child(element)
	match direction:
		Direction.LEFT_TO_RIGHT, Direction.TOP_TO_BOTTOM: pass
		Direction.RIGHT_TO_LEFT, Direction.BOTTOM_TO_TOP: _box_container.move_child(element, 0)
		_: assert(false, "Does not exist")

func remove(element: Control) -> void:
	assert(element)
	if not _box_container: return
	_box_container.remove_child(element)

func remove_last() -> Control:
	if not _box_container: return
	var last_element: Control = get_elements().back()
	remove(last_element)
	return last_element

func clear() -> void:
	if not _box_container: return
	assert(_box_container)
	for element: Control in get_elements():
		_box_container.remove_child(element)
		element.queue_free()

func get_elements() -> Array[Control]:
	var elements: Array[Control] = []
	if not _box_container: return elements
	elements.assign(_box_container.get_children())
	return elements

func for_each_element(callable: Callable) -> void:
	assert(_box_container)
	for element: Control in get_elements(): callable.call(element)

func _setup() -> void:
	match direction:
		Direction.LEFT_TO_RIGHT, Direction.RIGHT_TO_LEFT: _box_container = HBoxContainer.new()
		Direction.TOP_TO_BOTTOM, Direction.BOTTOM_TO_TOP: _box_container = VBoxContainer.new()
		_: assert(false, "Does not exist")

func _set_box_container(new_box_container: BoxContainer) -> void:
	assert(new_box_container)
	var root: Control = container_root if container_root else self
	var elements: Array[Control] = []
	if _box_container:
		elements = get_elements()
		for_each_element(func(element: Control) -> void: _box_container.remove_child(element))
		root.remove_child(_box_container)
		_box_container.queue_free()
	_box_container = new_box_container
	_box_container.alignment = alignment
	_box_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box_container.add_theme_constant_override("separation", separation)
	_box_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_box_container)
	for element: Control in elements: add(element)
	if container_index_in_root >= 0: root.move_child(_box_container, container_index_in_root)
