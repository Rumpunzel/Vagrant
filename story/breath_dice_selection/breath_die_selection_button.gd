@tool
class_name BreathDieSelectionButton
extends DisplayButton

signal breath_die_selected(breath_die: BreathDie)
signal breath_die_deselected(breath_die: BreathDie)

var breath_die: BreathDie :
	set(new_breath_die):
		assert(new_breath_die)
		assert(new_breath_die != breath_die)
		breath_die = new_breath_die
		icon = breath_die.die_type.icon
		text = ""
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

func update_save_request(save_request: SaveRequest) -> void:
	assert(save_request)
	active = true
	_on_selected_breath_dice_changed(save_request.selected_breath_dice)
	save_request.selected_breath_dice_changed.connect(_on_selected_breath_dice_changed)
	breath_die_selected.connect(save_request.select_breath_die)
	breath_die_deselected.connect(save_request.deselect_breath_die)

func update_save_result(save_result: SaveResult) -> void:
	assert(save_result)
	breath_die_selected.disconnect(save_result.save_request.select_breath_die)
	breath_die_deselected.disconnect(save_result.save_request.deselect_breath_die)
	if not save_result.save_request.selected_breath_dice.has(breath_die): return
	text = "%d" % breath_die.result
	_set_font_colors(save_result.get_die_color(breath_die))

func select() -> void:
	if not disabled: button_pressed = true

func deselect() -> void:
	if not disabled: button_pressed = false

func disable() -> void:
	active = false

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

func _on_selected_breath_dice_changed(selected_breath_dice: Array[BreathDie]) -> void:
	button_pressed = selected_breath_dice.has(breath_die)

func _on_die_rolled(_result: int, _state: BreathDie.State) -> void:
	update()

func _on_die_state_changed(_die_state: BreathDie.State) -> void:
	update()

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on: breath_die_selected.emit(breath_die)
	else: breath_die_deselected.emit(breath_die)
