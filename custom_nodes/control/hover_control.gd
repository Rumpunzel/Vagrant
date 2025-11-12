@tool
class_name HoverControl
extends Control

enum State {
	HIDDEN,
	SHOWING,
}

@export var _fade_time: float = 0.1

@export_group("Neighbors")
@export var _neighbor_hover_modulate: Color = Color(1.0, 1.0, 1.0, 0.25)
@export var _hover_neighbors: Array[HoverControl]

@onready var _modulate: Color = modulate

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
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", color_modulate, _fade_time)

func hide_icon() -> void:
	var hidden_modulate: Color = _modulate
	hidden_modulate.a = 0.0
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(self, "modulate", hidden_modulate, _fade_time)
	if is_inside_tree() and has_focus(): release_focus()

func get_state() -> State:
	return State.SHOWING if modulate.a > 0.0 else State.HIDDEN

func _show_icon(color_modulate: Color = _modulate) -> void:
	show_icon(color_modulate)
	for hover_button: HoverControl in _hover_neighbors:
		hover_button.show_icon(_neighbor_hover_modulate)

func _hide_icon() -> void:
	hide_icon()
	for hover_control: HoverControl in _hover_neighbors:
		hover_control.hide_icon()

func _on_mouse_entered() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): return
	_show_icon()

func _on_mouse_exited() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): return
	_hide_icon()
