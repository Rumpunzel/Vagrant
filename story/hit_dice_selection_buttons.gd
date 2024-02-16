extends PanelContainer

func update_hit_dice(available_hit_dice: Array[Die], attribute_score := 0) -> void:
	for button_group: HitDiceSelectionButtonGroup in _get_hit_dice_button_groups():
		button_group.update_hit_dice(available_hit_dice, attribute_score)

func select_all_available_buttons(select_buttons := true) -> void:
	for button_group: HitDiceSelectionButtonGroup in _get_hit_dice_button_groups():
		button_group.select_all_available_buttons(select_buttons)

func disable_buttons(save_difficulty := 0, set_to_disabled := true) -> void:
	for button_group: HitDiceSelectionButtonGroup in _get_hit_dice_button_groups():
		button_group.disable_buttons(save_difficulty, set_to_disabled)

func get_selected_dice() -> Array[Die]:
	var selected_dice: Array[Die] = [ ]
	for button_group: HitDiceSelectionButtonGroup in _get_hit_dice_button_groups():
		selected_dice.append_array(button_group.get_selected_dice())
	return selected_dice

func _get_hit_dice_button_groups() -> Array[Node]:
	return %HitDiceButtons.get_children()
