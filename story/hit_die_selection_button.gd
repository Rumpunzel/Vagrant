class_name HitDieSelectionButton
extends Button

var die: Die :
	set(new_die):
		if die != null: die.rolled.disconnect(_update_button)
		die = new_die
		_update_button(die)
		die.rolled.connect(_update_button)

func disable_button(save_difficulty := 0, attribute_score := 0, set_to_disabled := true) -> void:
	if button_pressed:
		text = "%d" % die.result if set_to_disabled else ""
		var font_color: Color = Color.TRANSPARENT
		if save_difficulty > 0 and die.result >= save_difficulty: font_color = Color.LIME_GREEN
		if attribute_score > 0 and die.result > attribute_score:
			font_color = Color.FIREBRICK if font_color == Color.TRANSPARENT else Color.ORANGE
		if font_color != Color.TRANSPARENT: _set_font_colors(font_color)
	toggle_mode = not set_to_disabled

func _update_button(_die: Die) -> void:
	icon = die.die_type.icon
	disabled = die.status == Die.Status.EXHAUSTED
	text = ""
	_remove_font_colors()

func _set_font_colors(color: Color) -> void:
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_disabled_color", color)
	add_theme_color_override("font_focus_color", color)
	add_theme_color_override("font_hover_color", color)

func _remove_font_colors() -> void:
	remove_theme_color_override("font_color")
	remove_theme_color_override("font_disabled_color")
	remove_theme_color_override("font_focus_color")
	remove_theme_color_override("font_hover_color")
