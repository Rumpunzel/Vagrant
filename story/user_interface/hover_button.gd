@tool
class_name HoverButton
extends Button

enum State {
	HIDDEN,
	SHOWING,
}

@export var _neighbor_hover_color: Color = Color(1.0, 1.0, 1.0, 0.25)
@export var _hover_neighbors: Array[HoverButton]

@onready var _modulate: Color = modulate
@onready var _icon: Texture2D = icon :
	set(new_icon):
		_icon = new_icon
		if icon: show_icon()

func _ready() -> void:
	if Engine.is_editor_hint(): return
	hide_icon()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _unhandled_key_input(event: InputEvent) -> void:
	if get_state() == State.SHOWING and event.is_action_pressed("ui_cancel"):
		_hide_icon()
		get_viewport().set_input_as_handled()

func show_icon(color_modulate: Color = _modulate) -> void:
	icon = _icon
	modulate = color_modulate

func hide_icon() -> void:
	icon = null
	modulate = _modulate
	if is_inside_tree() and has_focus(): release_focus()

func get_state() -> State:
	return State.SHOWING if icon else State.HIDDEN

func _show_icon(color_modulate: Color = _modulate) -> void:
	show_icon(color_modulate)
	for hover_button: HoverButton in _hover_neighbors:
		hover_button.show_icon(_neighbor_hover_color)

func _hide_icon() -> void:
	hide_icon()
	for hover_button: HoverButton in _hover_neighbors:
		hover_button.hide_icon()

func _on_mouse_entered() -> void:
	_show_icon()

func _on_mouse_exited() -> void:
	_hide_icon()
