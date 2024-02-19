class_name HitDieSelectionButton
extends Button

signal changed_disabled(disabled: bool)
signal changed_button_mask(button_mask: int)

enum DisplayResults {
	NEVER,
	ALWAYS,
}

var die: Die :
	set(new_die):
		if new_die == die: return
		if die != null: _disconnect_from_die()
		die = new_die
		if die != null: _connect_to_die()
		_on_die_changed(die)
		_on_toggled(button_pressed)

var display_results: DisplayResults = DisplayResults.NEVER
var save_difficulty := 0

func disable(set_to_disabled := true) -> void:
	disable_button_mask(set_to_disabled)
	if not set_to_disabled:
		_connect_to_die()
	else:
		_disconnect_from_die()

func _connect_to_die() -> void:
	die.rolled.connect(_on_die_changed)
	die.state_changed.connect(_on_die_save_selection_changed)

func _disconnect_from_die() -> void:
	die.rolled.disconnect(_on_die_changed)
	die.state_changed.disconnect(_on_die_save_selection_changed)

func _set_inactive(set_inactive := true) -> void:
	disable_button_mask(set_inactive)
	if not set_inactive:
		text = ""
		_remove_font_colors()
	elif display_results and button_pressed:
		text = "%d" % die.result
		_set_font_colors(die.get_die_color(save_difficulty))

func disable_button_mask(set_to_disabled := true) -> void:
	var new_button_mask := 0 if set_to_disabled else MOUSE_BUTTON_MASK_LEFT
	if new_button_mask == button_mask: return
	button_mask = new_button_mask
	changed_button_mask.emit(button_mask)

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

func _on_die_changed(_die: Die) -> void:
	icon = die.die_type.icon
	text = ""
	disabled = not die.is_alive()
	_on_die_save_selection_changed()
	changed_disabled.emit(disabled)

func _on_die_save_selection_changed(_die_state: Die.State = Die.State.ALIVE) -> void:
	if not die.is_considered():
		_set_inactive()
		return
	_set_inactive(false)
	button_pressed = die.is_selected()

func _on_toggled(toggled_on: bool) -> void:
	if not die.is_considered(): return
	var state := Die.State.SELECTED if toggled_on else Die.State.CONSIDERED
	die.update_state(state)
