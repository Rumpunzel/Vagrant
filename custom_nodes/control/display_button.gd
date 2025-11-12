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
	add_theme_color_override("font_pressed_color", color)
	add_theme_color_override("font_hover_color", color)
	add_theme_color_override("font_hover_pressed_color", color)
	add_theme_color_override("font_disabled_color", color.darkened(0.75) * Color(1.0, 1.0, 1.0, 0.5))
	add_theme_color_override("font_outline_color", color.darkened(0.75))

func remove_font_colors() -> void:
	remove_theme_color_override("font_color")
	remove_theme_color_override("font_pressed_color")
	remove_theme_color_override("font_hover_color")
	remove_theme_color_override("font_hover_pressed_color")
	remove_theme_color_override("font_disabled_color")
	remove_theme_color_override("font_outline_color")

func set_icon_colors(color: Color) -> void:
	add_theme_color_override("icon_normal_color", color)
	add_theme_color_override("icon_focus_color", color)
	add_theme_color_override("icon_pressed_color", color)
	add_theme_color_override("icon_hover_color", color)
	add_theme_color_override("icon_hover_pressed_color", color)
	add_theme_color_override("icon_disabled_color", color * Color(1.0, 1.0, 1.0, 0.4))

func remove_icon_colors() -> void:
	remove_theme_color_override("icon_normal_color")
	remove_theme_color_override("icon_focus_color")
	remove_theme_color_override("icon_pressed_color")
	remove_theme_color_override("icon_hover_color")
	remove_theme_color_override("icon_hover_pressed_color")
	remove_theme_color_override("icon_disabled_color")

func set_button_highlight_colors(color: Color, additional_highlight: Color = Color(0.25, 0.25, 0.25, 0.0)) -> void:
	remove_button_highlight_colors()
	var pressed_style_box: StyleBoxFlat = get_theme_stylebox("pressed").duplicate()
	pressed_style_box.bg_color = (pressed_style_box.bg_color + additional_highlight) * color
	add_theme_stylebox_override("pressed", pressed_style_box)
	var hover_style_box: StyleBoxFlat = get_theme_stylebox("hover").duplicate()
	hover_style_box.bg_color = (hover_style_box.bg_color + additional_highlight) * color
	add_theme_stylebox_override("hover", hover_style_box)
	var focus_style_box: StyleBoxFlat = get_theme_stylebox("focus").duplicate()
	focus_style_box.bg_color = (focus_style_box.bg_color + additional_highlight) * color
	add_theme_stylebox_override("focus", focus_style_box)

func remove_button_highlight_colors() -> void:
	remove_theme_stylebox_override("pressed")
	remove_theme_stylebox_override("hover")
	remove_theme_stylebox_override("focus")

func set_button_colors(color: Color, additional_highlight: Color = Color(0.1, 0.1, 0.1, 0.0)) -> void:
	var normal_style_box: StyleBoxFlat = get_theme_stylebox("normal").duplicate()
	normal_style_box.bg_color = (normal_style_box.bg_color + additional_highlight) * color
	add_theme_stylebox_override("normal", normal_style_box)
	var pressed_style_box: StyleBoxFlat = get_theme_stylebox("pressed").duplicate()
	pressed_style_box.bg_color = (pressed_style_box.bg_color + additional_highlight) * color
	add_theme_stylebox_override("pressed", pressed_style_box)
	var hover_style_box: StyleBoxFlat = get_theme_stylebox("hover").duplicate()
	hover_style_box.bg_color = (hover_style_box.bg_color + additional_highlight) * color
	add_theme_stylebox_override("hover", hover_style_box)
	var disabled_style_box: StyleBoxFlat = get_theme_stylebox("disabled").duplicate()
	disabled_style_box.bg_color = (disabled_style_box.bg_color + additional_highlight) * color
	add_theme_stylebox_override("disabled", disabled_style_box)
	var focus_style_box: StyleBoxFlat = get_theme_stylebox("focus").duplicate()
	focus_style_box.bg_color = (focus_style_box.bg_color + additional_highlight) * color
	add_theme_stylebox_override("focus", focus_style_box)

func remove_button_colors() -> void:
	remove_theme_stylebox_override("normal")
	remove_theme_stylebox_override("pressed")
	remove_theme_stylebox_override("hover")
	remove_theme_stylebox_override("disabled")
	remove_theme_stylebox_override("focus")
