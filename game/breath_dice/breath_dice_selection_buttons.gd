@tool
class_name BreathDiceSelectionButtons
extends BreathDice

func update_dice_request(dice_request: DiceRequest) -> void:
	_die_types.for_each_element(func(button_group: BreathDiceSelectionButtonGroup) -> void: button_group.update_dice_request(dice_request))
	if not dice_request: deactivate_buttons()

func select_all(selected: bool = true) -> void:
	_die_types.for_each_element(func(button_group: BreathDiceSelectionButtonGroup) -> void:
		if selected: button_group.select_all()
		else: button_group.deselect_all()
	)

func update_results(dice_result: DiceRequestResult) -> void:
	_die_types.for_each_element(func(button_group: BreathDiceSelectionButtonGroup) -> void: button_group.update_results(dice_result))

func update_colors(dice_result: DiceRequestResult) -> void:
	_die_types.for_each_element(func(button_group: BreathDiceSelectionButtonGroup) -> void: button_group.update_colors(dice_result))

func deactivate_buttons() -> void:
	_die_types.for_each_element(func(button_group: BreathDiceSelectionButtonGroup) -> void: button_group.deactivate())

## What it shows, as data ([PageRecord]), a die type each
func get_record() -> Array[Dictionary]:
	var groups: Array[Dictionary] = []
	for button_group: BreathDiceSelectionButtonGroup in _die_types.get_elements(): groups.append(button_group.get_record())
	return groups

func show_record(groups: Array) -> void:
	var counts: Dictionary[DieType, int] = {}
	var exhausted: Array[DieType] = []
	for group: Dictionary in groups:
		var die_type: DieType = ResourceId.find(group.die as String) as DieType
		counts[die_type] = int(group.count)
		if group.exhausted: exhausted.append(die_type)
	setup_breath_dice(counts)
	set_exhaustion(exhausted)
	for group: Dictionary in groups:
		var button_group: BreathDiceSelectionButtonGroup = button_groups.get(ResourceId.find(group.die as String)) as BreathDiceSelectionButtonGroup
		if button_group != null: button_group.show_record_buttons(group)
