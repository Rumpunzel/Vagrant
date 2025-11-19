@tool
class_name CarouselSelection
extends FlexContainer

signal item_selected(item_index: int)

@export var selected: int = -1 : set = _set_selected
@export var items: Array[String] = []:
	set(new_items):
		items = new_items
		var item_count: int = get_item_count()
		selected = mini(selected, item_count - 1)
		if _previous: _previous.disabled = item_count <= 1
		if _next: _next.disabled = item_count <= 1
@export var flat_buttons: bool

@export_group("Configuration")
@export var panel: PackedScene :
	set(new_panel):
		panel = new_panel
		_setup()
@export var previous_button: PackedScene :
	set(new_previous_button):
		previous_button = new_previous_button
		_setup()
@export var next_button: PackedScene :
	set(new_next_button):
		next_button = new_next_button
		_setup()

var _panel: CarouselPanel
var _previous: DisplayButton
var _next: DisplayButton

func set_item(index: int, text: String) -> void:
	if index >= get_item_count(): items.resize(index)
	items[index] = text

func get_item_count() -> int:
	return items.size()

func get_panel() -> CarouselPanel:
	return _panel

func get_previous() -> DisplayButton:
	return _previous

func get_next() -> DisplayButton:
	return _next

func enable_buttons() -> void:
	_previous.activate()
	_next.activate()

func deactivate_buttons() -> void:
	_previous.deactivate()
	_next.deactivate()

func _setup() -> void:
	super._setup()
	clear()
	## Previous Button
	if previous_button: _previous = previous_button.instantiate()
	else:
		_previous = DisplayButton.new()
		match direction:
			Direction.LEFT_TO_RIGHT: _previous.icon = preload("uid://buvbksy3o46rm")
			Direction.RIGHT_TO_LEFT: _previous.icon = preload("uid://ctxdc156sk6t4")
			Direction.TOP_TO_BOTTOM: _previous.icon = preload("uid://dbgcpwpmvj4vx")
			Direction.BOTTOM_TO_TOP: _previous.icon = preload("uid://vsrb4darihes")
			_: assert(false, "Does not exist")
		_previous.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_previous.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_previous.flat = flat_buttons
	_previous.name = "Previous"
	_previous.disabled = get_item_count() <= 1
	add(_previous)
	_previous.pressed.connect(_on_previous_pressed)
	## Panel
	if panel: _panel = panel.instantiate()
	else: _panel = preload("uid://djhw2fda1vbnb").instantiate()
	_panel.name = "Panel"
	match direction:
		Direction.LEFT_TO_RIGHT, Direction.RIGHT_TO_LEFT: _panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		Direction.TOP_TO_BOTTOM, Direction.BOTTOM_TO_TOP: _panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_: assert(false, "Does not exist")
	if selected >= 0: _panel.setup(items[selected])
	add(_panel)
	## Next Button
	if next_button: _next = next_button.instantiate()
	else:
		_next = DisplayButton.new()
		match direction:
			Direction.LEFT_TO_RIGHT: _next.icon = preload("uid://ctxdc156sk6t4")
			Direction.RIGHT_TO_LEFT: _next.icon = preload("uid://buvbksy3o46rm")
			Direction.TOP_TO_BOTTOM: _next.icon = preload("uid://vsrb4darihes")
			Direction.BOTTOM_TO_TOP: _next.icon = preload("uid://dbgcpwpmvj4vx")
			_: assert(false, "Does not exist")
		_next.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_next.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_next.name = "Next"
	_next.flat = flat_buttons
	_next.disabled = get_item_count() <= 1
	add(_next)
	_next.pressed.connect(_on_next_pressed)

func _set_selected(new_index: int) -> void:
	if get_item_count() > 0:
		selected = posmod(new_index, get_item_count())
		if _panel: _panel.setup(items[selected])
	else: selected = -1
	if selected > 0: if _panel: _panel.setup(items[selected])
	item_selected.emit(selected)

func _on_previous_pressed() -> void:
	selected -= 1

func _on_next_pressed() -> void:
	selected += 1
