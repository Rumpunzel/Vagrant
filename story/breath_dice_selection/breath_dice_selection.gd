@tool
class_name BreathDiceSelection
extends PanelContainer

signal confirmed

@export var _portrait_identifier: String = "Small.png"

@export_group("Configuration")
@export var _portrait: TextureRect
@export var _description: TypingLabel
@export var _stance_selection_collapsible_container: CollapsibleContainer
@export var _stance_selection_buttons: StanceSelectionButtons
@export var _breath_dice_selection_buttons: BreathDiceSelectionButtons
@export var _all_in_button: DisplayButton
@export var _ok_button: DisplayButton
@export var _dice_log_dice_request_entry: DiceLogDiceRequestEntry
@export var _dice_log_save_result_entry: DiceLogSaveResultEntry

var _dice_request: DiceRequest :
	set(new_dice_request):
		assert(new_dice_request)
		_dice_request = new_dice_request
		_portrait.texture = _dice_request.character.character_profile.get_portrait(_portrait_identifier)
		_description.type_text(_dice_request.get_description())
		var character: Character = _dice_request.character
		_dice_log_dice_request_entry.initialize_dice_request(_dice_request)
		_dice_log_dice_request_entry.visible = true
		_dice_log_save_result_entry.visible = false
		_breath_dice_selection_buttons.setup_breath_dice(character.breath_dice)
		_breath_dice_selection_buttons.update_dice_request(_dice_request)
		_enable_hud()
		_all_in_button.set_pressed_no_signal(false)
		#_ok_button.grab_focus()

func request_save(save_request: SaveRequest) -> void:
	assert(save_request)
	_dice_request = save_request
	save_request.save_rolled.connect(_on_save_rolled)

func request_fight(fight_request: FightRequest) -> void:
	if not fight_request:
		_stance_selection_collapsible_container.close_tween()
		return
	assert(fight_request)
	_dice_request = fight_request
	_stance_selection_buttons.request_fight(fight_request)
	await get_tree().process_frame
	_stance_selection_collapsible_container.open_tween()

func _enable_hud() -> void:
	_ok_button.disabled = false
	_ok_button.active = true
	_all_in_button.disabled = false
	_all_in_button.active = true

func _disable_hud() -> void:
	_ok_button.disabled = true
	_ok_button.active = false
	_all_in_button.disabled = true
	_all_in_button.active = false

func _on_confirmed() -> void:
	confirmed.emit()

func _on_save_rolled(save_result: SaveResult) -> void:
	assert(save_result)
	assert(save_result.save_request == _dice_request)
	_dice_log_save_result_entry.initialize_save_result(save_result)
	_dice_log_dice_request_entry.visible = false
	_dice_log_save_result_entry.visible = true
	_breath_dice_selection_buttons.update_save_result(save_result)
	_breath_dice_selection_buttons.disable_buttons()
	_disable_hud()
