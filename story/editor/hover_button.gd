@tool
class_name HoverButton
extends Button

@onready var _icon: Texture2D = icon

func _ready() -> void:
	add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	if Engine.is_editor_hint(): return
	icon = null
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	icon = _icon

func _on_mouse_exited() -> void:
	icon = null
