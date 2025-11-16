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
@export var trigger_control: Control

@export var fade_behavior: Behavior = Behavior.SHOW_ON_HOVER
@export var fade_in_time: float = 0.1
@export var fade_in_delay: float = 0.0
@export var fade_out_time: float = 0.1
@export var fade_out_delay: float = 0.1
@export var hide_on_fade_out: bool

@export_group("Neighbors")
@export var hover_neighbors: Array[HoverFade] = []
@export var neighbor_hover_modulate: Color = Color(1.0, 1.0, 1.0, 0.25)

var _modulate: Color
var _fade_tween: Tween

func _ready() -> void:
	if not control_to_fade: control_to_fade = get_parent()
	if not trigger_control: trigger_control = control_to_fade
	assert(control_to_fade)
	assert(trigger_control)
	assert(not hover_neighbors.has(self), "Neighbours cannot contain self!")
	if Engine.is_editor_hint(): return
	_modulate = control_to_fade.modulate
	match fade_behavior:
		Behavior.SHOW_ON_HOVER:
			control_to_fade.modulate.a = 0
			if hide_on_fade_out: hide()
		Behavior.HIDE_ON_HOVER:
			control_to_fade.modulate.a = 1.0
			if hide_on_fade_out: show()
		_: assert(false, "Does not exist")
	trigger_control.mouse_entered.connect(_on_mouse_entered)
	trigger_control.mouse_exited.connect(_on_mouse_exited)
	trigger_control.focus_entered.connect(_on_focus_entered)
	trigger_control.focus_exited.connect(_on_focus_exited)

func _unhandled_key_input(event: InputEvent) -> void:
	if get_state() == State.HOVERED and event.is_action_pressed("ui_cancel"):
		_on_unhover()
		get_viewport().set_input_as_handled()

func show(color_modulate: Color = _modulate, show_neighbours: bool = true) -> void:
	_fade_in(color_modulate)
	if not show_neighbours: return
	for hover_fade: HoverFade in hover_neighbors: hover_fade.show(neighbor_hover_modulate, false)

func hide(show_neighbours: bool = true) -> void:
	_fade_out()
	if not show_neighbours: return
	for hover_fade: HoverFade in hover_neighbors: hover_fade.hide(false)

func get_state() -> State:
	match fade_behavior:
		Behavior.SHOW_ON_HOVER: return State.HOVERED if control_to_fade.modulate.a > 0.0 else State.UNHOVERED
		Behavior.HIDE_ON_HOVER: return State.HOVERED if control_to_fade.modulate.a < 1.0 else State.UNHOVERED
		_: assert(false, "Does not exist")
	return State.UNHOVERED

func _fade_in(color_modulate: Color = _modulate) -> void:
	if hide_on_fade_out: control_to_fade.show()
	if _fade_tween: _fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(control_to_fade, "modulate", color_modulate, fade_in_time).set_delay(fade_in_delay)

func _fade_out() -> void:
	if _fade_tween: _fade_tween.kill()
	var hidden_modulate: Color = _modulate
	hidden_modulate.a = 0.0
	_fade_tween = create_tween()
	_fade_tween.tween_property(control_to_fade, "modulate", hidden_modulate, fade_out_time).set_delay(fade_out_delay)
	await _fade_tween.finished
	if is_inside_tree() and control_to_fade.has_focus(): control_to_fade.release_focus()
	if hide_on_fade_out: control_to_fade.hide()

func _on_hover() -> void:
	match fade_behavior:
		Behavior.SHOW_ON_HOVER: show()
		Behavior.HIDE_ON_HOVER: hide()
		_: assert(false, "Does not exist")

func _on_unhover() -> void:
	match fade_behavior:
		Behavior.SHOW_ON_HOVER: hide()
		Behavior.HIDE_ON_HOVER: show()
		_: assert(false, "Does not exist")

func _on_mouse_entered() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): return
	_on_hover()

func _on_mouse_exited() -> void:
	if trigger_control.has_focus() or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): return
	_on_unhover()

func _on_focus_entered() -> void:
	_on_hover()

func _on_focus_exited() -> void:
	if trigger_control.get_global_rect().has_point(trigger_control.get_global_mouse_position()): return
	_on_unhover()
