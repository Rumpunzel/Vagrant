@tool
class_name BreathDieSelectionButton
extends DisplayButton

signal breath_die_selected(breath_die: BreathDie)
signal breath_die_deselected(breath_die: BreathDie)

@export var _randomly_delay_update: bool = true
@export_range(0.0, 5.0) var _min_update_delay: float = 0.1
@export_range(0.0, 5.0) var _max_update_delay: float = 1.0

@export_group("Configuration")
@export var _update_timer: Timer

var breath_die: BreathDie :
	set(new_breath_die):
		assert(new_breath_die)
		assert(new_breath_die != breath_die)
		breath_die = new_breath_die
		icon = breath_die.die_type.icon
		text = ""
		_update()
		breath_die.state_changed.connect(_on_die_state_changed)

@onready var _update_delay: float = randf_range(_min_update_delay, _max_update_delay)

func update_dice_request(dice_request: DiceRequest) -> void:
	assert(dice_request)
	active = true
	_on_selected_breath_dice_changed(dice_request.selected_breath_dice)
	dice_request.selected_breath_dice_changed.connect(_on_selected_breath_dice_changed)
	breath_die_selected.connect(dice_request.select_breath_die)
	breath_die_deselected.connect(dice_request.deselect_breath_die)

func update_save_result(save_result: SaveResult) -> void:
	assert(save_result)
	breath_die_selected.disconnect(save_result.save_request.select_breath_die)
	breath_die_deselected.disconnect(save_result.save_request.deselect_breath_die)
	if not save_result.save_request.selected_breath_dice.has(breath_die): return
	if is_inside_tree() and _randomly_delay_update:
		_update_timer.start(_update_delay)
		await _update_timer.timeout
	text = "%d" % breath_die.result
	set_font_colors(save_result.get_die_color(breath_die))
	_update()

func update_fight_result(fight_result: FightResult) -> void:
	assert(fight_result)
	breath_die_selected.disconnect(fight_result.fight_request.select_breath_die)
	breath_die_deselected.disconnect(fight_result.fight_request.deselect_breath_die)
	if not fight_result.fight_request.selected_breath_dice.has(breath_die): return
	if is_inside_tree() and _randomly_delay_update:
		_update_timer.start(_update_delay)
		await _update_timer.timeout
	text = "%d" % breath_die.result
	#set_font_colors(fight_result.get_die_color(breath_die))
	_update()

func _update() -> void:
	disabled = not breath_die.is_alive()
	if disabled:
		tooltip_text = "This die is exhausted."
		mouse_default_cursor_shape = Control.CURSOR_HELP
	else:
		tooltip_text = "[%s]" % breath_die.die_type
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _on_selected_breath_dice_changed(selected_breath_dice: Array[BreathDie]) -> void:
	button_pressed = selected_breath_dice.has(breath_die)

func _on_die_state_changed(_die_state: BreathDie.State) -> void:
	# Only update in real time outside of breath die selection
	if button_pressed: return
	_update()

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on: breath_die_selected.emit(breath_die)
	else: breath_die_deselected.emit(breath_die)
