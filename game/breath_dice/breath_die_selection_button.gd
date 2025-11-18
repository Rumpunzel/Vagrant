@tool
class_name BreathDieSelectionButton
extends BreathDieButton

signal breath_die_selected(breath_die: BreathDie)
signal breath_die_deselected(breath_die: BreathDie)

@export var _randomly_delay_update: bool = true
@export_range(0.0, 5.0) var _min_update_delay: float = 0.1
@export_range(0.0, 5.0) var _max_update_delay: float = 1.0
@export_range(0.0, 5.0) var _reveal_delay: float = 1.5

@export_group("Configuration")
@export var _update_delay_timer: Timer

func update_dice_request(dice_request: DiceRequest) -> void:
	assert(dice_request)
	active = true
	_on_selected_breath_dice_changed(dice_request.selected_breath_dice)
	dice_request.selected_breath_dice_changed.connect(_on_selected_breath_dice_changed)
	breath_die_selected.connect(dice_request.select_breath_die)
	breath_die_deselected.connect(dice_request.deselect_breath_die)

func update_save_result(save_result: SaveResult) -> void:
	assert(save_result)
	save_result.save_request.selected_breath_dice_changed.disconnect(_on_selected_breath_dice_changed)
	breath_die_selected.disconnect(save_result.save_request.select_breath_die)
	breath_die_deselected.disconnect(save_result.save_request.deselect_breath_die)
	if not save_result.save_request.selected_breath_dice.has(breath_die): return
	var update_delay: float = randf_range(_min_update_delay, _max_update_delay)
	if is_inside_tree() and _randomly_delay_update:
		_update_delay_timer.start(update_delay)
		await _update_delay_timer.timeout
	text = "%d" % breath_die.result
	_update()
	if is_inside_tree():
		if not _randomly_delay_update: update_delay = _max_update_delay
		_update_delay_timer.start(_reveal_delay - update_delay)
		await _update_delay_timer.timeout
	set_font_colors(save_result.get_die_color(breath_die))

func update_fight_result(fight_result: FightResult) -> void:
	assert(fight_result)
	fight_result.fight_request.selected_breath_dice_changed.disconnect(_on_selected_breath_dice_changed)
	breath_die_selected.disconnect(fight_result.fight_request.select_breath_die)
	breath_die_deselected.disconnect(fight_result.fight_request.deselect_breath_die)
	if not fight_result.fight_request.selected_breath_dice.has(breath_die): return
	var update_delay: float = randf_range(_min_update_delay, _max_update_delay)
	if is_inside_tree() and _randomly_delay_update:
		_update_delay_timer.start(update_delay)
		await _update_delay_timer.timeout
	text = "%d" % breath_die.result
	_update()
	#set_font_colors(fight_result.get_die_color(breath_die))

func _on_selected_breath_dice_changed(selected_breath_dice: Array[BreathDie]) -> void:
	button_pressed = selected_breath_dice.has(breath_die)

func _on_die_state_changed(alive: bool) -> void:
	# Only update in real time outside of breath die selection
	if button_pressed: return
	super._on_die_state_changed(alive)

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on: breath_die_selected.emit(breath_die)
	else: breath_die_deselected.emit(breath_die)
