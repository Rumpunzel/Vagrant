class_name HitDieSelectionButton
extends Button

signal changed_disabled(disabled: bool)

var die: Die :
	set(new_die):
		if new_die == die: return
		if die:
			die.rolled.disconnect(_on_die_changed)
			die.reconsidered_for_save.disconnect(_on_reconsidered_for_save)
		die = new_die
		_on_die_changed()
		_on_toggled(button_pressed)
		if die:
			die.rolled.connect(_on_die_changed)
			die.reconsidered_for_save.connect(_on_reconsidered_for_save)

func disable_button(save_difficulty := 0, set_to_disabled := true) -> void:
	button_mask = 0 if set_to_disabled else MOUSE_BUTTON_MASK_LEFT
	if not button_pressed: return
	text = "%d" % die.result if set_to_disabled else ""
	_set_font_colors(die.get_die_color(save_difficulty))

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

func _on_die_changed(_die: Die = null) -> void:
	icon = die.die_type.icon
	text = ""
	disabled = not die.is_alive()
	changed_disabled.emit(disabled)

func _on_reconsidered_for_save(selected_for_save: bool) -> void:
	button_pressed = selected_for_save

func _on_toggled(toggled_on: bool) -> void:
	die.selected_for_save = toggled_on
