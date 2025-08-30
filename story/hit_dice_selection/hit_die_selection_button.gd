@tool
class_name HitDieSelectionButton
extends DisplayButton

signal changed_disabled(disabled: bool)

var die: Die :
	set(new_die):
		assert(new_die)
		assert(new_die != die)
		die = new_die
		_connect_to_die()
		_on_die_changed(die)
		_on_toggled(button_pressed)

func update_for_save_result(save_result: SaveResult) -> void:
	if not save_result:
		text = ""
		_remove_font_colors()
		return
	if not die.is_selected(): return
	text = "%d" % die.result
	_set_font_colors(save_result.get_die_color(die))

func _connect_to_die() -> void:
	die.rolled.connect(_on_die_changed)
	die.state_changed.connect(_on_die_save_selection_changed)

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

func _on_die_changed(new_die: Die) -> void:
	icon = new_die.die_type.icon
	text = ""
	disabled = not die.is_alive()
	if disabled:
		tooltip_text = "This die is exhausted."
		mouse_default_cursor_shape = Control.CURSOR_HELP
	else:
		tooltip_text = "[%s]" % new_die.die_type
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_on_die_save_selection_changed(new_die.state)
	changed_disabled.emit(disabled)

func _on_die_save_selection_changed(die_state: Die.State) -> void:
	button_pressed = die_state >= Die.State.SELECTED

func _on_toggled(toggled_on: bool) -> void:
	die.state = Die.State.SELECTED if toggled_on else Die.State.ALIVE
