@tool
class_name DisplayButton
extends Button

signal activation_changed(new_status: bool)

@export var active: bool = true :
	set(new_status):
		if new_status == active: return
		active = new_status
		button_mask = MOUSE_BUTTON_MASK_LEFT if active else 0
		focus_mode = Control.FOCUS_ALL if active else Control.FOCUS_NONE
		mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_PASS
		activation_changed.emit(active)

func select() -> void:
	if not disabled: button_pressed = true

func deselect() -> void:
	if not disabled: button_pressed = false

func enable() -> void:
	active = true

func disable() -> void:
	active = false

func set_font_colors(color: Color) -> void:
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_disabled_color", color)
	add_theme_color_override("font_pressed_color", color)
	add_theme_color_override("font_hover_color", color)

func remove_font_colors() -> void:
	remove_theme_color_override("font_color")
	remove_theme_color_override("font_disabled_color")
	remove_theme_color_override("font_pressed_color")
	remove_theme_color_override("font_hover_color")
