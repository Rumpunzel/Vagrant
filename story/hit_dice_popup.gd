extends ConfirmationDialog

const _OK_BUTTON := "Roll %s Dice!"

func show_hit_dice_selection(character: Character, attribute: Character.Attributes, difficulty: int, description: String) -> void:
	ok_button_text = _OK_BUTTON % Character.Attributes.find_key(attribute)
	$HitDiceSelection.update_dice_selection(character, attribute, difficulty, description)
	popup_centered()
