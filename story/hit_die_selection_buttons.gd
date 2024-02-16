extends HBoxContainer

func update_buttons(available_hit_dice: Array[Die], attribute_score := 0) -> void:
	for button_group: HitDieSelectionButtonGroupWrapper in get_children():
		button_group.update_buttons(available_hit_dice, attribute_score)

func select_all_available_buttons(select_buttons := true) -> void:
	for wrapper: HitDieSelectionButtonGroupWrapper in get_children():
		wrapper.select_all_available_buttons(select_buttons)

func disable_buttons(save_difficulty := 0, set_to_disabled := true) -> void:
	for wrapper: HitDieSelectionButtonGroupWrapper in get_children():
		wrapper.disable_buttons(save_difficulty, set_to_disabled)

func get_selected_dice() -> Array[Die]:
	var selected_dice: Array[Die] = [ ]
	for wrapper: HitDieSelectionButtonGroupWrapper in get_children():
		selected_dice.append_array(wrapper.get_selected_dice())
	return selected_dice
