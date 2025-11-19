@tool
class_name BreathDiceSelectionButtons
extends BreathDice

func update_dice_request(dice_request: DiceRequest) -> void:
	_die_types.for_each_element(func(button_group: BreathDiceSelectionButtonGroup) -> void: button_group.update_dice_request(dice_request))

func update_save_result(save_result: SaveResult) -> void:
	_die_types.for_each_element(func(button_group: BreathDiceSelectionButtonGroup) -> void: button_group.update_save_result(save_result))

func update_fight_result(fight_result: FightResult) -> void:
	_die_types.for_each_element(func(button_group: BreathDiceSelectionButtonGroup) -> void: button_group.update_fight_result(fight_result))

func select_all(selected: bool = true) -> void:
	_die_types.for_each_element(func(button_group: BreathDiceSelectionButtonGroup) -> void: if selected: button_group.select_all() else: button_group.deselect_all())

func deactivate_buttons() -> void:
	_die_types.for_each_element(func(button_group: BreathDiceSelectionButtonGroup) -> void: button_group.deactivate())
