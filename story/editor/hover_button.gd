@tool
class_name HoverButton
extends Button

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

func show_icon(color_modulate: Color = _modulate) -> void:
	icon = _icon
	modulate = color_modulate

func hide_icon() -> void:
	icon = null
	modulate = _modulate
	release_focus()

func _on_mouse_entered() -> void:
	show_icon()
	for hover_button: HoverButton in _hover_neighbors:
		hover_button.show_icon(_neighbor_hover_color)

func _on_mouse_exited() -> void:
	hide_icon()
	for hover_button: HoverButton in _hover_neighbors:
		hover_button.hide_icon()
