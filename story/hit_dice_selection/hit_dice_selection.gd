class_name HitDiceSelection
extends PanelContainer

signal save_evaluated(save_result: SaveResult)

@export_group("Configuration")
@export var _portrait: TextureRect
@export var _description: TypingLabel
@export var _hit_dice_selection_buttons: HitDiceSelectionButtons
@export var _all_in_button: DisplayButton
@export var _ok_button: DisplayButton
@export var _dice_log_entry: DiceLogEntry

var _save_request: SaveRequest = null
var _save_result: SaveResult = null

func request_save(save_request: SaveRequest) -> void:
	_save_request = save_request
	if _save_request == null: return
	var character: Character = _save_request.character
	var available_hit_dice: Array[Die] = character.get_available_hit_dice()
	_portrait.texture = character.portrait
	_description.type_text(_save_request.description)
	_enable_hud()
	_all_in_button.set_pressed_no_signal(false)
	_hit_dice_selection_buttons.update_hit_dice(available_hit_dice)
	_dice_log_entry.initialize_save_request(save_request)
	_ok_button.grab_focus()

func _roll_save(dice_to_roll: Array[Die]) -> void:
	_save_result = DiceRoller.roll_save(dice_to_roll, _save_request)
	_dice_log_entry.initialize_save_result(_save_result)
	save_evaluated.emit(_save_result)

func _enable_hud(set_to_enabled: bool = true) -> void:
	_ok_button.disabled = not set_to_enabled
	_ok_button.active = set_to_enabled
	_all_in_button.disabled = not set_to_enabled
	_all_in_button.active = set_to_enabled

func _on_confirmed() -> void:
	_roll_save(_hit_dice_selection_buttons.get_selected_dice())
	_hit_dice_selection_buttons.disable_buttons()
	_enable_hud(false)
