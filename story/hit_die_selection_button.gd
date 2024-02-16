class_name HitDieSelectionButton
extends Button

var die: Die :
	set(new_die):
		if new_die == die: return
		if die: die.rolled.disconnect(_on_die_change)
		die = new_die
		_on_die_change()
		if die: die.rolled.connect(_on_die_change)

func disable_button(save_difficulty := 0, set_to_disabled := true) -> void:
	button_mask = 0 if set_to_disabled else MOUSE_BUTTON_MASK_LEFT
	if not button_pressed: return
	var die_exhausted := die.status == Die.Status.EXHAUSTED
	text = "%d" % die.result if set_to_disabled else ""
	var save_succeeded := die.result >= save_difficulty
	var font_color: Color = Color.TRANSPARENT
	if save_difficulty <= 0 or save_succeeded:
		font_color = Color.LIME_GREEN if not die_exhausted else Color.CORNFLOWER_BLUE
	else:
		font_color = Color.ORANGE if not die_exhausted else Color.FIREBRICK
	if font_color != Color.TRANSPARENT: _set_font_colors(font_color)

func _set_font_colors(color: Color) -> void:
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_disabled_color", color)
	add_theme_color_override("font_pressed_color", color)
	add_theme_color_override("font_hover_color", color)

func _remove_font_colors() -> void:
	remove_theme_color_override("font_color")
	remove_theme_color_override("font_disabled_color")
	remove_theme_color_override("font_pressed_color")
	remove_theme_color_override("font_hover_color")

func _on_die_change(_die: Die = null) -> void:
	icon = die.die_type.icon
	text = ""
	disabled = die.status == Die.Status.EXHAUSTED
