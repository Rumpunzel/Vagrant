class_name HitDiceSelection
extends PanelContainer

signal dice_selection_configured(character: Character, attribute: CharacterAttribute)
signal confirmed(save_result: DiceRoller.SaveResult)

var _save_request: HitDiceSelection.SaveRequest = null

func _enter_tree() -> void:
	Events.save_requested.connect(request_save)

func _exit_tree() -> void:
	Events.save_requested.disconnect(request_save)

func request_save(save_request: HitDiceSelection.SaveRequest) -> void:
	_save_request = save_request
	var character := _save_request.character
	var hit_dice := character.hit_dice
	var attribute := _save_request.attribute
	var difficulty := _save_request.difficulty
	%d4.update_dice_amount(hit_dice.get_dice_count(DiceRoller.Dice.d4), DiceRoller.Dice.d4)
	%d6.update_dice_amount(hit_dice.get_dice_count(DiceRoller.Dice.d6), DiceRoller.Dice.d6)
	%d8.update_dice_amount(hit_dice.get_dice_count(DiceRoller.Dice.d8), DiceRoller.Dice.d8)
	%d10.update_dice_amount(hit_dice.get_dice_count(DiceRoller.Dice.d10), DiceRoller.Dice.d10)
	%d12.update_dice_amount(hit_dice.get_dice_count(DiceRoller.Dice.d12), DiceRoller.Dice.d12)
	%Portrait.texture = character.portrait
	%Description.text = _save_request.description
	
	%OKButton.disabled = false
	%OKButton.visible = true
	%DiceLogEntry.visible = false
	dice_selection_configured.emit(character, attribute)

func _on_confirmed() -> void:
	var dice_to_roll := DicePool.new()
	for _i in range(%d4.value):
		dice_to_roll.add_die(DiceRoller.Dice.d4)
	for _i in range(%d6.value):
		dice_to_roll.add_die(DiceRoller.Dice.d6)
	for _i in range(%d8.value):
		dice_to_roll.add_die(DiceRoller.Dice.d8)
	for _i in range(%d10.value):
		dice_to_roll.add_die(DiceRoller.Dice.d10)
	for _i in range(%d12.value):
		dice_to_roll.add_die(DiceRoller.Dice.d12)
	
	var save_result := DiceRoller.roll_save(dice_to_roll, _save_request)
	
	%d4.editable = false
	%d6.editable = false
	%d8.editable = false
	%d10.editable = false
	%d12.editable = false
	%OKButton.disabled = true
	%OKButton.visible = false
	%DiceLogEntry.visible = true
	%DiceLogEntry.initialize_save_result(save_result)
	Events.save_evaluated.emit(save_result, _save_request)
	confirmed.emit(save_result)

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
