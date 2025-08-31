@tool
class_name HitDiceSelectionButtons
extends PanelContainer

@export_group("Configuration")
@export var _breath_dice_buttons: Container
@export var _breath_dice_selection_group: PackedScene

var _button_groups: Dictionary[DieType, HitDiceSelectionButtonGroup] = {}

func setup_breath_dice(breath_dice: Array[BreathDie]) -> void:
	_button_groups.clear()
	_clear()
	for breath_die: BreathDie in breath_dice:
		var button_group: HitDiceSelectionButtonGroup = _button_groups.get(breath_die.die_type)
		if not button_group:
			button_group = _breath_dice_selection_group.instantiate()
			button_group.breath_die_type = breath_die.die_type
			_button_groups[breath_die.die_type] = button_group
			_breath_dice_buttons.add_child(button_group)
		button_group.add_button(breath_die)

func update_save_request(save_request: SaveRequest) -> void:
	for button_group: HitDiceSelectionButtonGroup in _get_button_groups():
		button_group.update_save_request(save_request)

func update_save_result(save_result: SaveResult) -> void:
	for button_group: HitDiceSelectionButtonGroup in _get_button_groups():
		button_group.update_save_result(save_result)

func select_all(selected: bool = true) -> void:
	for button_group: HitDiceSelectionButtonGroup in _get_button_groups():
		if selected: button_group.select_all()
		else: button_group.deselect_all()

func disable_buttons() -> void:
	for button_group: HitDiceSelectionButtonGroup in _get_button_groups():
		button_group.disable()

func _clear() -> void:
	for child: Node in _breath_dice_buttons.get_children():
		_breath_dice_buttons.remove_child(child)
		child.queue_free()

func _get_button_groups() -> Array[HitDiceSelectionButtonGroup]:
	var button_groups: Array[HitDiceSelectionButtonGroup] = []
	button_groups.assign(_breath_dice_buttons.get_children())
	return button_groups
