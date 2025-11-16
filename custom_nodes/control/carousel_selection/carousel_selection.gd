@tool
class_name CarouselSelection
extends PanelContainer

signal item_selected(item_index: int)

@export var selected: int = -1 : get = _get_selected, set = _set_selected
@export var items: Array[String] = []:
	set(new_items):
		items = new_items
		var item_count: int = get_item_count()
		selected = mini(selected, item_count - 1)
		_previous.disabled = item_count <= 1
		_next.disabled = item_count <= 1
@export var tooltips: Dictionary[int, String] = {}

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

@export_group("Layout")
@export var margin_left: int = 0 :
	set(new_margin_left):
		margin_left = new_margin_left
		_flex_container.add_theme_constant_override("margin_left", new_margin_left)
@export var margin_top: int = 0 :
	set(new_margin_top):
		margin_top = new_margin_top
		_flex_container.add_theme_constant_override("margin_top", margin_top)
@export var margin_right: int = 0 :
	set(new_margin_right):
		margin_right = new_margin_right
		_flex_container.add_theme_constant_override("margin_right", margin_right)
@export var margin_bottom: int = 0 :
	set(new_margin_bottom):
		margin_bottom = new_margin_bottom
		_flex_container.add_theme_constant_override("margin_bottom", margin_bottom)
@export var flex_alignment: BoxContainer.AlignmentMode = BoxContainer.AlignmentMode.ALIGNMENT_CENTER :
	set(new_flex_alignment):
		flex_alignment = new_flex_alignment
		_flex_container.alignment = flex_alignment
@export var direction: FlexContainer.Direction :
	get: return _flex_container.direction
	set(new_direction): _flex_container.direction = new_direction

var _flex_container: FlexContainer
var _panel: CarouselPanel
var _previous: CarouselButton
var _next: CarouselButton

func _init() -> void:
	_setup_flex_container()
	_setup_carousel()

func set_item(index: int, text: String) -> void:
	if index >= get_item_count(): items.resize(index)
	items[index] = text

func set_tooltip(index: int, tooltip: String) -> void:
	assert(index < get_item_count())
	tooltips[index] = tooltip

func get_item_count() -> int:
	return items.size()

func get_panel() -> CarouselPanel:
	return _panel

func get_previous() -> CarouselButton:
	return _previous

func get_next() -> CarouselButton:
	return _next

func enable_buttons() -> void:
	_previous.activate()
	_next.activate()

func deactivate_buttons() -> void:
	_previous.deactivate()
	_next.deactivate()

func _setup_flex_container() -> void:
	assert(not _flex_container)
	_flex_container = FlexContainer.new()
	_flex_container.fill = false
	_flex_container.alignment = flex_alignment
	_flex_container.direction = direction
	_flex_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flex_container.add_theme_constant_override("margin_left", margin_left)
	_flex_container.add_theme_constant_override("margin_top", margin_top)
	_flex_container.add_theme_constant_override("margin_right", margin_right)
	_flex_container.add_theme_constant_override("margin_bottom", margin_bottom)
	add_child(_flex_container, true, Node.INTERNAL_MODE_BACK)

func _setup_carousel() -> void:
	_flex_container.clear()
	## Previous Button
	if previous_button: _previous = previous_button.instantiate()
	else:
		_previous = preload("uid://bio0tn8287gj").instantiate()
		_previous.setup(preload("uid://buvbksy3o46rm"))
	_previous.name = "Previous"
	_flex_container.add(_previous)
	_previous.pressed.connect(_on_previous_pressed)
	## Panel
	if panel: _panel = panel.instantiate()
	else: _panel = preload("uid://djhw2fda1vbnb").instantiate()
	_panel.name = "Panel"
	match direction:
		FlexContainer.Direction.LEFT_TO_RIGHT, FlexContainer.Direction.RIGHT_TO_LEFT: _panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		FlexContainer.Direction.TOP_TO_BOTTOM, FlexContainer.Direction.BOTTOM_TO_TOP: _panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_: assert(false, "Does not exist")
	_flex_container.add(_panel)
	## Next Button
	if next_button: _next = next_button.instantiate()
	else:
		_next = preload("uid://bio0tn8287gj").instantiate()
		_next.setup(preload("uid://ctxdc156sk6t4"))
	_next.name = "Next"
	_flex_container.add(_next)
	_next.pressed.connect(_on_next_pressed)

func _get_selected() -> int:
	return posmod(selected, get_item_count()) if get_item_count() > 0 else -1

func _set_selected(new_index: int) -> void:
	if get_item_count() > 0:
		selected = posmod(new_index, get_item_count())
		var tooltip_strings: Array[String] = []
		tooltip_strings.assign([tooltips[selected]] if tooltips.has(selected) else [])
		_panel.setup(items[selected], tooltip_strings)
	else: selected = -1
	if selected > 0: _panel.setup(items[selected])
	item_selected.emit(selected)

func _on_previous_pressed() -> void:
	selected -= 1

func _on_next_pressed() -> void:
	selected += 1
