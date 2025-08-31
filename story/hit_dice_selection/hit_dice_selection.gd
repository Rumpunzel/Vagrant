class_name HitDiceSelection
extends PanelContainer

signal save_evaluated(save_result: SaveResult)

@export_group("Configuration")
@export var _portrait: TextureRect
@export var _description: TypingLabel
@export var _breath_dice_selection_buttons: HitDiceSelectionButtons
@export var _all_in_button: DisplayButton
@export var _ok_button: DisplayButton
@export var _dice_log_save_request_entry: DiceLogSaveRequestEntry
@export var _dice_log_save_result_entry: DiceLogSaveResultEntry

var _save_request: SaveRequest :
	set(new_save_request):
		assert(new_save_request)
		_save_request = new_save_request
		_description.type_text(_save_request.description)
		_enable_hud()
		_all_in_button.set_pressed_no_signal(false)
		_dice_log_save_request_entry.initialize_save_request(_save_request, _character_resolver)
		_dice_log_save_request_entry.visible = true
		_dice_log_save_result_entry.visible = false
		_breath_dice_selection_buttons.update_save_request(_save_request)
		var character: Character = _character_resolver.call(_save_request.character_profile)
		_breath_dice_selection_buttons.setup_breath_dice(character.breath_dice)
		_portrait.texture = character.portrait
		_ok_button.grab_focus()
	
var _save_result: SaveResult :
	set(new_save_result):
		assert(new_save_result)
		assert(new_save_result.save_request == _save_request)
		_save_result = new_save_result
		_dice_log_save_result_entry.initialize_save_result(_save_result, _character_resolver)
		_dice_log_save_request_entry.visible = false
		_dice_log_save_result_entry.visible = true
		_breath_dice_selection_buttons.update_save_result(_save_result)
		_breath_dice_selection_buttons.disable_buttons()
		_disable_hud()

var _character_resolver: Callable

func request_save(save_request: SaveRequest, character_resolver: Callable) -> void:
	assert(save_request)
	assert(character_resolver)
	_character_resolver = character_resolver
	_save_request = save_request

func _roll_save() -> void:
	assert(_save_request)
	assert(_character_resolver)
	_save_result = _save_request.roll_save(_character_resolver)
	save_evaluated.emit(_save_result)

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
	_roll_save()
