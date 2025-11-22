class_name PopoutWindow
extends Window

@export_group("Configuration")
@export var _popout_button: Button
@export var _close_button: Button

var _embedded_position: Vector2i
var _native_position: Vector2i

func _ready() -> void:
	await  get_tree().process_frame
	child_controls_changed()

func add(control: Control, is_main: bool = true) -> void:
	add_child(control)
	move_child(control, 0)
	if is_main: title = control.name

func popup_above(control: Control, offset: Vector2) -> void:
	popup()
	await get_tree().process_frame
	position = Vector2(control.global_position.x - control.global_position.x * 0.5, control.global_position.y - size.y) + offset

func popout() -> void:
	assert(not force_native)
	assert(visible)
	var delta_moved: Vector2i = position - _embedded_position
	_embedded_position = position
	hide()
	force_native = true
	borderless = false
	_popout_button.hide()
	_close_button.hide()
	show()
	if _native_position: position = _native_position
	else: position = get_tree().root.position 
	position += delta_moved
	position = position.clamp(Vector2i.ZERO, DisplayServer.screen_get_size(DisplayServer.SCREEN_OF_MAIN_WINDOW) - size)
	request_attention()

func popin() -> void:
	assert(force_native)
	_native_position = position
	var was_visible: bool = visible
	hide()
	force_native = false
	borderless = true
	_popout_button.show()
	_close_button.show()
	mode = Window.MODE_WINDOWED
	if was_visible: show()
	position = _embedded_position

func close() -> void:
	if not visible: return
	if force_native: mode = Window.MODE_MINIMIZED
	else: hide()

func _on_visibility_changed() -> void:
	await get_tree().process_frame
	size = Vector2i.ZERO

func _on_child_entered_tree(node: Node) -> void:
	if not node is Control: return
	var control: Control = node
	control.gui_input.connect(_on_child_gui_input)

func _on_child_exiting_tree(node: Node) -> void:
	if not node is Control: return
	var control: Control = node
	control.gui_input.disconnect(_on_child_gui_input)

func _on_child_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button_event: InputEventMouseButton = event
		if mouse_button_event.button_index == MOUSE_BUTTON_LEFT and mouse_button_event.pressed:
			start_drag()

func _on_pop_out_pressed() -> void:
	popout()

func _on_close_pressed() -> void:
	assert(not force_native)
	hide()

func _on_close_requested() -> void:
	if force_native: popin()
	else: close()
