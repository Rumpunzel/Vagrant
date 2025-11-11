@tool
class_name FlexContainer
extends Container

enum Direction {
	LEFT_TO_RIGHT,
	RIGHT_TO_LEFT,
	TOP_TO_BOTTOM,
	BOTTOM_TO_TOP,
}

@export_range(0.0, 256.0, 1.0, "exp", "suffix:px") var _element_size: float = 64.0
@export_range(0, 64, 1, "suffix:px") var _separation: int = 4
@export var _direction: Direction = Direction.LEFT_TO_RIGHT :
	set(new_direction):
		if new_direction == _direction: return
		_direction = new_direction
		_setup()

var _box_container: BoxContainer

func _ready() -> void:
	_setup()

func add(element: Control) -> void:
	assert(_box_container)
	if _element_size > 0.0: element.custom_minimum_size = Vector2(_element_size, _element_size)
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
	assert(_box_container)
	for element: Control in _box_container.get_children():
		_box_container.remove_child(element)
		element.queue_free()

func get_elements() -> Array[Control]:
	var elements: Array[Control] = []
	elements.assign(_box_container.get_children())
	return elements

func for_each_element(callable: Callable) -> void:
	for element: Control in get_elements(): callable.call(element)

func _setup() -> void:
	if _box_container: clear()
	match _direction:
		Direction.LEFT_TO_RIGHT, Direction.RIGHT_TO_LEFT: _box_container = HBoxContainer.new()
		Direction.TOP_TO_BOTTOM, Direction.BOTTOM_TO_TOP: _box_container = VBoxContainer.new()
		_: assert(false, "Does not exist")
	_box_container.add_theme_constant_override("separation", _separation)
	add_child(_box_container)
