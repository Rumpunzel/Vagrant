class_name HitDieSelectionButtonGroupWrapper
extends VBoxContainer

@export var hit_die_type: DieType

func update_buttons(available_hit_dice: Array[Die], attribute_score := 0) -> void:
	var relevant_hit_dice: Array[Die] = [ ]
	for die: Die in available_hit_dice:
		if die.die_type == hit_die_type: relevant_hit_dice.append(die)
	var all_buttons_auto_selected: bool = %Buttons.update_buttons(relevant_hit_dice, attribute_score)
	%AllButton.visible = relevant_hit_dice.size() > 1
	%AllButton.disabled = false
	%AllButton.set_pressed_no_signal(all_buttons_auto_selected)
	visible = not relevant_hit_dice.is_empty()

func select_all_available_buttons(select_buttons := true) -> void:
	%AllButton.set_pressed_no_signal(select_buttons)
	%Buttons.select_all_available_buttons(select_buttons)

func disable_buttons(save_difficulty := 0, set_to_disabled := true) -> void:
	%AllButton.disabled = true
	%Buttons.disable_buttons(save_difficulty, set_to_disabled)

func get_selected_dice() -> Array[Die]:
	return %Buttons.get_selected_dice()
