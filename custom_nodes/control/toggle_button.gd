@tool
class_name ToggleButton
extends Button

@export var toggled_off_icon: Texture2D = icon
@export var toggled_on_icon: Texture2D

func _init() -> void:
	_on_toggled(button_pressed)
	toggled.connect(_on_toggled)

func _on_toggled(toggled_on: bool) -> void:
	icon = toggled_on_icon if toggled_on else toggled_off_icon
