class_name WindowBlurToggler
extends Node

@export var trigger_window: Window :
	set(new_trigger_window):
		trigger_window = new_trigger_window
		if trigger_window: _on_visibility_changed()
		trigger_window.visibility_changed.connect(_on_visibility_changed)

func _ready() -> void:
	if not trigger_window: trigger_window = get_parent()
	assert(trigger_window)

func _on_visibility_changed() -> void:
	assert(trigger_window)
	if trigger_window.visible: BlurLayer.fade_in()
	else: BlurLayer.fade_out()
