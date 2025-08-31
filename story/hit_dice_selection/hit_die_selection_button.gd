@tool
class_name HitDieSelectionButton
extends DisplayButton

signal changed_disabled(disabled: bool)

var breath_die: BreathDie :
	set(new_bewth_die):
		assert(new_bewth_die)
		assert(new_bewth_die != breath_die)
		breath_die = new_bewth_die
		icon = breath_die.die_type.icon
		text = ""
		_on_toggled(button_pressed)
		update()
		breath_die.rolled.connect(_on_die_rolled)
		breath_die.state_changed.connect(_on_die_state_changed)

func _ready() -> void:
	disable()

func update() -> void:
	disabled = not breath_die.is_alive()
	if disabled:
		tooltip_text = "This die is exhausted."
		mouse_default_cursor_shape = Control.CURSOR_HELP
	else:
		tooltip_text = "[%s]" % breath_die.die_type
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	#button_pressed = breath_die.state >= BreathDie.State.SELECTED
	changed_disabled.emit(disabled)

func update_save_request(save_request: SaveRequest) -> void:
	active = true
	button_pressed = save_request.selected_breath_dice.has(breath_die)

func update_save_result(save_result: SaveResult) -> void:
	if not save_result:
		text = ""
		_remove_font_colors()
		return
	#if not breath_die.is_selected(): return
	text = "%d" % breath_die.result
	_set_font_colors(save_result.get_die_color(breath_die))

func select() -> void:
	if not disabled: button_pressed = true

func deselect() -> void:
	if not disabled: button_pressed = false

func disable() -> void:
	active = false

func get_selected() -> Array[BreathDie]:
	if button_pressed: return [breath_die]
	return []

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

func _on_die_rolled(_result: int, _state: BreathDie.State) -> void:
	update()

func _on_die_state_changed(_die_state: BreathDie.State) -> void:
	update()

func _on_toggled(toggled_on: bool) -> void:
	pass
	#die.state = BreathDie.State.SELECTED if toggled_on else BreathDie.State.ALIVE
