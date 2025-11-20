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

var current_dice_request: DiceRequest :
	set(new_current_dice_request):
		if current_dice_request:
			current_dice_request.selected_breath_dice_changed.disconnect(_on_selected_breath_dice_changed)
			breath_die_selected.disconnect(current_dice_request.select_breath_die)
			breath_die_deselected.disconnect(current_dice_request.deselect_breath_die)
			if current_dice_request is SaveRequest: current_dice_request.rolled.disconnect(_on_save_rolled)
			elif current_dice_request is FightRequest: current_dice_request.rolled.disconnect(_on_fight_rolled)
		current_dice_request = new_current_dice_request
		if current_dice_request:
			active = true
			text = ""
		else:
			active = false
			return
		_on_selected_breath_dice_changed(current_dice_request.selected_breath_dice)
		current_dice_request.selected_breath_dice_changed.connect(_on_selected_breath_dice_changed)
		breath_die_selected.connect(current_dice_request.select_breath_die)
		breath_die_deselected.connect(current_dice_request.deselect_breath_die)
		if current_dice_request is SaveRequest: current_dice_request.rolled.connect(_on_save_rolled)
		elif current_dice_request is FightRequest: current_dice_request.rolled.connect(_on_fight_rolled)
		else: assert(false, "Not implemented!")

func deactivate(reset_on_deactivation: bool = false) -> void:
	active = false
	if reset_on_deactivation:
		assert(toggle_mode)
		await get_tree().create_timer(_reveal_delay).timeout
		button_pressed = false

func _on_selected_breath_dice_changed(selected_breath_dice: Array[BreathDie]) -> void:
	button_pressed = selected_breath_dice.has(breath_die)

func _on_die_state_changed(alive: bool) -> void:
	# Only update in real time outside of breath die selection
	if button_pressed: return
	super._on_die_state_changed(alive)

func _on_save_rolled(save_result: SaveResult) -> void:
	assert(save_result)
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

func _on_fight_rolled(fight_result: FightResult) -> void:
	assert(fight_result)
	if not fight_result.fight_request.selected_breath_dice.has(breath_die): return
	var update_delay: float = randf_range(_min_update_delay, _max_update_delay)
	if is_inside_tree() and _randomly_delay_update:
		_update_delay_timer.start(update_delay)
		await _update_delay_timer.timeout
	text = "%d" % breath_die.result
	_update()
	#set_font_colors(fight_result.get_die_color(breath_die))

func _on_toggled(toggled_on: bool) -> void:
	if toggled_on: breath_die_selected.emit(breath_die)
	else: breath_die_deselected.emit(breath_die)
