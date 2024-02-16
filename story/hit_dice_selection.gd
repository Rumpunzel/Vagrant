class_name HitDiceSelection
extends PanelContainer

signal dice_selection_configured(character: Character, attribute: CharacterAttribute)
signal confirmed(save_result: SaveResult)

var _save_request: SaveRequest = null

func _enter_tree() -> void:
	Events.save_requested.connect(request_save)

func _exit_tree() -> void:
	Events.save_requested.disconnect(request_save)

func request_save(save_request: SaveRequest) -> void:
	_save_request = save_request
	var character := _save_request.character
	%Portrait.texture = character.portrait
	%Description.text = _save_request.description
	%OKButton.disabled = false
	%AllInButton.disabled = false
	%AllInButton.set_pressed_no_signal(false)
	%Buttons.visible = true
	%DiceLogEntry.visible = false
	%HitDieSelectionButtons.update_buttons(character.get_available_hit_dice(), character.get_attribute_score(save_request.attribute))
	dice_selection_configured.emit(character, _save_request.attribute)

func _roll_save(dice_to_roll: Array[Die]) -> void:
	var save_result: SaveResult = DiceRoller.roll_save(dice_to_roll, _save_request)
	%OKButton.disabled = true
	%AllInButton.disabled = true
	%Buttons.visible = false
	%DiceLogEntry.visible = true
	%DiceLogEntry.initialize_save_result(save_result)
	%HitDieSelectionButtons.disable_buttons(save_result.difficulty)
	Events.save_evaluated.emit(save_result, _save_request)
	confirmed.emit(save_result)

func _on_confirmed() -> void:
	_roll_save(%HitDieSelectionButtons.get_selected_dice())

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
