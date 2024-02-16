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

func disable_buttons(set_to_disabled := true) -> void:
	for button: HitDieSelectionButton in get_children():
		button.toggle_mode = not set_to_disabled

func get_selected_dice() -> Array[Die]:
	var selected_dice: Array[Die] = [ ]
	for button: HitDieSelectionButton in get_children():
		if button.button_pressed: selected_dice.append(button.die)
	return selected_dice
