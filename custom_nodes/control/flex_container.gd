@tool
class_name FlexContainer
extends MarginContainer

enum Direction {
	LEFT_TO_RIGHT,
	RIGHT_TO_LEFT,
	TOP_TO_BOTTOM,
	BOTTOM_TO_TOP,
}

@export_range(0.0, 256.0, 1.0, "exp", "suffix:px") var _element_size: float = 64.0
@export_range(-64, 64, 1, "suffix:px") var _separation: int = 4
@export var _fill: bool = true
@export var _container_root: Control = self
@export var _container_index_in_root: int = -1
@export var _direction: Direction = Direction.LEFT_TO_RIGHT :
	set(new_direction):
		if new_direction == _direction: return
		_direction = new_direction
		_setup()

var _box_container: BoxContainer

func add(element: Control) -> void:
	if not _box_container: _setup()
	assert(_box_container)
	if _element_size > 0.0: element.custom_minimum_size = Vector2(_element_size, _element_size)
	if _fill:
		match _direction:
			Direction.LEFT_TO_RIGHT, Direction.RIGHT_TO_LEFT: element.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			Direction.TOP_TO_BOTTOM, Direction.BOTTOM_TO_TOP: element.size_flags_vertical = Control.SIZE_EXPAND_FILL
			_: assert(false, "Does not exist")
	_box_container.add_child(element)
	match _direction:
		Direction.LEFT_TO_RIGHT, Direction.TOP_TO_BOTTOM: pass
		Direction.RIGHT_TO_LEFT, Direction.BOTTOM_TO_TOP: _box_container.move_child(element, 0)
		_: assert(false, "Does not exist")

func clear() -> void:
	if not _box_container: return
	assert(_box_container)
	for element: Control in _box_container.get_children():
		_box_container.remove_child(element)
		element.queue_free()

func get_elements() -> Array[Control]:
	var elements: Array[Control] = []
	elements.assign(_box_container.get_children())
	return elements

func for_each_element(callable: Callable) -> void:
	for element: Control in _box_container.get_children(): callable.call(element)

func _setup() -> void:
	var container_root: Control = _container_root if _container_root else self
	var elements: Array[Control] = []
	if _box_container:
		elements = get_elements()
		for_each_element(func(element: Control) -> void: _box_container.remove_child(element))
		container_root.remove_child(_box_container)
		_box_container.queue_free()
	match _direction:
		Direction.LEFT_TO_RIGHT, Direction.RIGHT_TO_LEFT: _box_container = HBoxContainer.new()
		Direction.TOP_TO_BOTTOM, Direction.BOTTOM_TO_TOP: _box_container = VBoxContainer.new()
		_: assert(false, "Does not exist")
	_box_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_box_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_box_container.add_theme_constant_override("separation", _separation)
	container_root.add_child(_box_container)
	for element: Control in elements: add(element)
	if _container_index_in_root >= 0: container_root.move_child(_box_container, _container_index_in_root)
