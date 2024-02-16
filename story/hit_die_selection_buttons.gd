extends HFlowContainer

@export var _hit_die_selection_button: PackedScene

func update_buttons(available_hit_dice: Array[Die]) -> void:
	for button: HitDieSelectionButton in get_children():
		remove_child(button)
		button.queue_free()
	for hit_die: Die in available_hit_dice:
		var hit_die_selection_button: HitDieSelectionButton = _hit_die_selection_button.instantiate()
		hit_die_selection_button.die = hit_die
		add_child(hit_die_selection_button)

func select_all_available_buttons(select_buttons := true) -> void:
	for button: HitDieSelectionButton in get_children():
		if not button.disabled: button.button_pressed = select_buttons

func disable_buttons(save_difficulty := 0, attribute_score := 0, set_to_disabled := true) -> void:
	for button: HitDieSelectionButton in get_children():
		button.disable_button(save_difficulty, attribute_score, set_to_disabled)

func get_selected_dice() -> Array[Die]:
	var selected_dice: Array[Die] = [ ]
	for button: HitDieSelectionButton in get_children():
		if button.button_pressed: selected_dice.append(button.die)
	return selected_dice
