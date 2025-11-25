@tool
class_name BreathDieSelectionButton
extends BreathDieButton

@export var _randomly_delay_update: bool = true
@export_range(0.0, 5.0) var _min_update_delay: float = 0.1
@export_range(0.0, 5.0) var _max_update_delay: float = 1.0
@export_range(0.0, 5.0) var _reveal_delay: float = 1.5

@export_group("Configuration")
@export var _update_delay_timer: Timer
@export var _lost_sounds: AudioStreamPlayer

var current_dice_request: DiceRequest :
	set(new_current_dice_request):
		if current_dice_request:
			current_dice_request.selected_breath_dice_changed.disconnect(_on_selected_breath_dice_changed)
		current_dice_request = new_current_dice_request
		_update()
		if not current_dice_request:
			active = false
			return
		active = true
		text = ""
		current_dice_request.selected_breath_dice_changed.connect(_on_selected_breath_dice_changed)

func update_result(result: int) -> void:
	var update_delay: float = randf_range(_min_update_delay, _max_update_delay)
	if is_inside_tree() and _randomly_delay_update:
		_update_delay_timer.start(update_delay)
		await _update_delay_timer.timeout
	text = "%d" % result

func update_state(dice_result: DiceRequestResult, breath_die: Die) -> void:
	assert(dice_result)
	assert(breath_die)
	set_font_colors(dice_result.get_die_color(breath_die))
	var was_lost: bool = dice_result.get_lost_breath_dice().has(breath_die)
	disabled = was_lost
	if was_lost: _lost_sounds.play()

func deactivate(reset_on_deactivation: bool = false) -> void:
	active = false
	if reset_on_deactivation:
		assert(toggle_mode)
		await get_tree().create_timer(_reveal_delay).timeout
		button_pressed = false

func _update() -> void:
	var selected: bool = current_dice_request and current_dice_request.selected_breath_dice.get(die_type, 0) > 0
	set_pressed_no_signal(selected)

func _on_selected_breath_dice_changed(selected_breath_dice: Dictionary[DieType, int]) -> void:
	assert(selected_breath_dice == current_dice_request.selected_breath_dice)
	_update()

func _on_toggled(toggled_on: bool) -> void:
	assert(current_dice_request)
	if toggled_on: current_dice_request.select_breath_die(die_type)
	else: current_dice_request.deselect_breath_die(die_type)
