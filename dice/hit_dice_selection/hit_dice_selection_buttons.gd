class_name HitDiceSelectionButtons
extends PanelContainer

@export var _display_results: HitDieSelectionButton.DisplayResults = HitDieSelectionButton.DisplayResults.NEVER

@export_group("Configuration")
@export var _hit_dice_buttons: Container

func update_hit_dice(available_hit_dice: Array[Die], save_difficulty := 0) -> void:
	for button_group: HitDiceSelectionButtonGroup in _get_hit_dice_button_groups():
		button_group.update_hit_dice(available_hit_dice, _display_results, save_difficulty)

func select_all_available_buttons(select_buttons := true) -> void:
	for button_group: HitDiceSelectionButtonGroup in _get_hit_dice_button_groups():
		button_group.select_all_available_buttons(select_buttons)

func get_selected_dice() -> Array[Die]:
	var selected_dice: Array[Die] = [ ]
	for button_group: HitDiceSelectionButtonGroup in _get_hit_dice_button_groups():
		selected_dice.append_array(button_group.get_selected_dice())
	return selected_dice

func _get_hit_dice_button_groups() -> Array[Node]:
	return _hit_dice_buttons.get_children()
