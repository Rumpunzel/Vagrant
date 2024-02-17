class_name HitDiceSelection
extends PanelContainer

signal dice_selection_configured(character: Character, attribute: CharacterAttribute)
signal confirmed(save_result: SaveResult)

@export_group("Configuration")
@export var _portrait: TextureRect
@export var _description: RichTextLabel
@export var _hit_dice_selection_buttons: HitDiceSelectionButtons
@export var _buttons: Container
@export var _all_in_button: Button
@export var _ok_button: Button
@export var _dice_log_entry: DiceLogEntry

var _save_request: SaveRequest = null

func _enter_tree() -> void:
	Events.save_requested.connect(request_save)

func _exit_tree() -> void:
	Events.save_requested.disconnect(request_save)

func request_save(save_request: SaveRequest) -> void:
	_save_request = save_request
	var character := _save_request.character
	var available_hit_dice := character.get_available_hit_dice()
	var attribute_score := character.get_attribute_score(save_request.attribute)
	_portrait.texture = character.portrait
	_description.text = _save_request.description
	_ok_button.disabled = false
	_all_in_button.disabled = false
	_all_in_button.set_pressed_no_signal(false)
	_buttons.visible = true
	_dice_log_entry.visible = false
	_hit_dice_selection_buttons.update_hit_dice(available_hit_dice, attribute_score)
	dice_selection_configured.emit(character, _save_request.attribute)

func _roll_save(dice_to_roll: Array[Die]) -> void:
	var save_result: SaveResult = DiceRoller.roll_save(dice_to_roll, _save_request)
	_ok_button.disabled = true
	_all_in_button.disabled = true
	_buttons.visible = false
	_dice_log_entry.visible = true
	_dice_log_entry.initialize_save_result(save_result)
	#_hit_dice_selection_buttons.disable_buttons(save_result.difficulty)
	Events.save_evaluated.emit(save_result, _save_request)
	confirmed.emit(save_result)

func _on_confirmed() -> void:
	_roll_save(_hit_dice_selection_buttons.get_selected_dice())

class SaveRequest:
	var character: Character
	var attribute: CharacterAttribute
	var difficulty: int
	var description: String
	
	func _init(new_character: Character, new_attribute: CharacterAttribute, new_difficulty: int, new_description: String):
		character = new_character
		attribute = new_attribute
		difficulty = new_difficulty
		description = new_description
		
		var available_hit_dice := character.get_available_hit_dice()
		for hit_die: Die in available_hit_dice:
			hit_die.save_selection = Die.SaveSelection.CONSIDERED
