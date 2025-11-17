@tool
class_name CarouselSelection
extends HBoxContainer

signal item_selected(item_index: int)

@export var selected: int = -1 : set = _set_selected
@export var items: Array[String] = []:
	set(new_items):
		items = new_items
		var item_count: int = get_item_count()
		selected = mini(selected, item_count - 1)
		_previous.disabled = item_count <= 1
		_next.disabled = item_count <= 1
@export var flat_buttons: bool = false

@export_group("Configuration")
@export var panel: PackedScene :
	set(new_panel):
		panel = new_panel
		_setup_carousel()
@export var previous_button: PackedScene :
	set(new_previous_button):
		previous_button = new_previous_button
		_setup_carousel()
@export var next_button: PackedScene :
	set(new_next_button):
		next_button = new_next_button
		_setup_carousel()

var _panel: CarouselPanel
var _previous: DisplayButton
var _next: DisplayButton

func _init() -> void:
	_setup_carousel()

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

func _setup_carousel() -> void:
	_clear()
	## Previous Button
	if previous_button: _previous = previous_button.instantiate()
	else:
		_previous = DisplayButton.new()
		_previous.icon = preload("uid://buvbksy3o46rm")
		_previous.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_previous.flat = flat_buttons
	_previous.name = "Previous"
	add_child(_previous, true, Node.INTERNAL_MODE_BACK)
	_previous.pressed.connect(_on_previous_pressed)
	## Panel
	if panel: _panel = panel.instantiate()
	else: _panel = preload("uid://djhw2fda1vbnb").instantiate()
	_panel.name = "Panel"
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(_panel, true, Node.INTERNAL_MODE_BACK)
	## Next Button
	if next_button: _next = next_button.instantiate()
	else:
		_next = DisplayButton.new()
		_next.icon = preload("uid://ctxdc156sk6t4")
		_next.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_next.name = "Next"
	_next.flat = flat_buttons
	add_child(_next, true, Node.INTERNAL_MODE_BACK)
	_next.pressed.connect(_on_next_pressed)

func _clear() -> void:
	if _previous:
		remove_child(_previous)
		_previous.queue_free()
	if _panel:
		remove_child(_panel)
		_panel.queue_free()
	if _next:
		remove_child(_next)
		_next.queue_free()

func _set_selected(new_index: int) -> void:
	if get_item_count() > 0:
		selected = posmod(new_index, get_item_count())
		_panel.setup(items[selected])
	else: selected = -1
	if selected > 0: _panel.setup(items[selected])
	item_selected.emit(selected)

func _on_previous_pressed() -> void:
	selected -= 1

func _on_next_pressed() -> void:
	selected += 1
