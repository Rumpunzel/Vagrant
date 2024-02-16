class_name HitDiceSelectionButtonGroup
extends VBoxContainer

@export var _hit_die_selection_button: PackedScene
@export var hit_die_type: DieType :
	set(new_hit_die_type):
		hit_die_type = new_hit_die_type
		%AllButton.text = "%s" % hit_die_type

func update_hit_dice(available_hit_dice: Array[Die], attribute_score := 0) -> void:
	var all_buttons_auto_selected := true
	var relevant_hit_dice: Array[Die] = [ ]
	for die: Die in available_hit_dice:
		if die.die_type == hit_die_type: relevant_hit_dice.append(die)
	for button: HitDieSelectionButton in _get_hit_die_selection_buttons():
		button.toggled.disconnect(_on_button_toggled)
		%Buttons.remove_child(button)
		button.queue_free()
	
	for hit_die: Die in relevant_hit_dice:
		var button: HitDieSelectionButton = _hit_die_selection_button.instantiate()
		button.die = hit_die
		var dice_auto_selected := attribute_score >= hit_die.die_type.faces
		if dice_auto_selected:
			button.button_pressed = true
		all_buttons_auto_selected = all_buttons_auto_selected and dice_auto_selected
		button.toggled.connect(_on_button_toggled)
		%Buttons.add_child(button)
	
	%AllButton.disabled = false
	%AllButton.set_pressed_no_signal(all_buttons_auto_selected)
	visible = not relevant_hit_dice.is_empty()

func select_all_available_buttons(select_buttons := true) -> void:
	%AllButton.set_pressed_no_signal(select_buttons)
	for button: HitDieSelectionButton in _get_hit_die_selection_buttons():
		if not button.disabled: button.button_pressed = select_buttons

func disable_buttons(save_difficulty := 0, set_to_disabled := true) -> void:
	%AllButton.disabled = true
	for button: HitDieSelectionButton in _get_hit_die_selection_buttons():
		button.disable_button(save_difficulty, set_to_disabled)

func get_selected_dice() -> Array[Die]:
	var selected_dice: Array[Die] = [ ]
	for button: HitDieSelectionButton in _get_hit_die_selection_buttons():
		if button.button_pressed: selected_dice.append(button.die)
	return selected_dice

func _get_hit_die_selection_buttons() -> Array[Node]:
	return %Buttons.get_children()

func _on_button_toggled(_toggled_on: bool) -> void:
	var all_buttons_selected := true
	for button: HitDieSelectionButton in _get_hit_die_selection_buttons():
		all_buttons_selected = all_buttons_selected and button.button_pressed
	%AllButton.set_pressed_no_signal(all_buttons_selected)
