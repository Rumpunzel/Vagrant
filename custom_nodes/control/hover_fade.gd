@tool
class_name HoverFade
extends Node

enum Behavior {
	SHOW_ON_HOVER,
	HIDE_ON_HOVER,
}

enum State {
	UNHOVERED,
	HOVERED,
}

@export var control_to_fade: Control

@export var _fade_behavior: Behavior = Behavior.SHOW_ON_HOVER
@export var _fade_time: float = 0.1

@export_group("Neighbors")
@export var hover_neighbors: Array[HoverFade] = []
@export var _neighbor_hover_modulate: Color = Color(1.0, 1.0, 1.0, 0.25)

var _modulate: Color

func _ready() -> void:
	if not control_to_fade: control_to_fade = get_parent()
	assert(not hover_neighbors.has(self), "Neighbours cannot contain self!")
	if Engine.is_editor_hint(): return
	_modulate = control_to_fade.modulate
	match _fade_behavior:
		Behavior.SHOW_ON_HOVER: control_to_fade.modulate.a = 0
		Behavior.HIDE_ON_HOVER: control_to_fade.modulate.a = 1.0
		_: assert(false, "Does not exist")
	control_to_fade.mouse_entered.connect(_on_mouse_entered)
	control_to_fade.mouse_exited.connect(_on_mouse_exited)
	control_to_fade.focus_entered.connect(_on_focus_entered)
	control_to_fade.focus_exited.connect(_on_mouse_entered)

func _unhandled_key_input(event: InputEvent) -> void:
	if get_state() == State.HOVERED and event.is_action_pressed("ui_cancel"):
		_on_unhover()
		get_viewport().set_input_as_handled()

func show(color_modulate: Color = _modulate, show_neighbours: bool = true) -> void:
	_fade_in(color_modulate)
	if not show_neighbours: return
	for hover_fade: HoverFade in hover_neighbors: hover_fade.show(_neighbor_hover_modulate, false)

func hide(show_neighbours: bool = true) -> void:
	_fade_out()
	if not show_neighbours: return
	for hover_fade: HoverFade in hover_neighbors: hover_fade.hide(false)

func get_state() -> State:
	match _fade_behavior:
		Behavior.SHOW_ON_HOVER: return State.HOVERED if control_to_fade.modulate.a > 0.0 else State.UNHOVERED
		Behavior.HIDE_ON_HOVER: return State.HOVERED if control_to_fade.modulate.a < 1.0 else State.UNHOVERED
		_: assert(false, "Does not exist")
	return State.UNHOVERED

func _fade_in(color_modulate: Color = _modulate) -> void:
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(control_to_fade, "modulate", color_modulate, _fade_time)

func _fade_out() -> void:
	var hidden_modulate: Color = _modulate
	hidden_modulate.a = 0.0
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(control_to_fade, "modulate", hidden_modulate, _fade_time)
	if is_inside_tree() and control_to_fade.has_focus(): control_to_fade.release_focus()

func _on_hover() -> void:
	match _fade_behavior:
		Behavior.SHOW_ON_HOVER: show()
		Behavior.HIDE_ON_HOVER: hide()
		_: assert(false, "Does not exist")

func _on_unhover() -> void:
	match _fade_behavior:
		Behavior.SHOW_ON_HOVER: hide()
		Behavior.HIDE_ON_HOVER: show()
		_: assert(false, "Does not exist")

func _on_mouse_entered() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): return
	_on_hover()

func _on_mouse_exited() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): return
	_on_unhover()

func _on_focus_entered() -> void:
	_on_hover()

func _on_focus_exited() -> void:
	if control_to_fade.get_global_rect().has_point(control_to_fade.get_global_mouse_position()): return
	_on_unhover()
