@tool
class_name BreathDiceSelectionButtons
extends BreathDice

@export var _reset_on_deactivation: bool

func update_dice_request(dice_request: DiceRequest) -> void:
	_die_types.for_each_element(func(button_group: BreathDiceSelectionButtonGroup) -> void: button_group.update_dice_request(dice_request))
	if not dice_request: deactivate_buttons()

func select_all(selected: bool = true) -> void:
	_die_types.for_each_element(func(button_group: BreathDiceSelectionButtonGroup) -> void: if selected: button_group.select_all() else: button_group.deselect_all())

func deactivate_buttons() -> void:
	_die_types.for_each_element(func(button_group: BreathDiceSelectionButtonGroup) -> void: button_group.deactivate(_reset_on_deactivation))
