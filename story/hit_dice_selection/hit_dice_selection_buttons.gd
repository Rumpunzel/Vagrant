@tool
class_name HitDiceSelectionButtons
extends PanelContainer

@export_group("Configuration")
@export var _breath_dice_buttons: Container
@export var _breath_dice_selection_group: PackedScene
@export var _breath_dice_selection_button: PackedScene

func setup_breath_dice(breath_dice: Array[BreathDie]) -> void:
	_clear()
	for breath_die: BreathDie in breath_dice:
		var breath_dice_selection_button: HitDieSelectionButton = _breath_dice_selection_button.instantiate()
		breath_dice_selection_button.breath_die = breath_die
		_breath_dice_buttons.add_child(breath_dice_selection_button)

func update_save_request(save_request: SaveRequest) -> void:
	for button_group: HitDieSelectionButton in _get_breath_dice_button_implements():
		button_group.update_save_request(save_request)

func update_save_result(save_result: SaveResult) -> void:
	for button_group: HitDieSelectionButton in _get_breath_dice_button_implements():
		button_group.update_save_result(save_result)

func select_all() -> void:
	for button_group: HitDieSelectionButton in _get_breath_dice_button_implements():
		button_group.select_all()

func deselect_all() -> void:
	for button_group: HitDieSelectionButton in _get_breath_dice_button_implements():
		button_group.deselect_all()

func disable_buttons() -> void:
	for button_group: HitDieSelectionButton in _get_breath_dice_button_implements():
		button_group.disable()

func get_selected_dice() -> Array[BreathDie]:
	var selected_dice: Array[BreathDie] = [ ]
	for button_group: HitDieSelectionButton in _get_breath_dice_button_implements():
		selected_dice.append_array(button_group.get_selected())
	return selected_dice

func _clear() -> void:
	for child: Node in _breath_dice_buttons.get_children():
		_breath_dice_buttons.remove_child(child)
		child.queue_free()

# -> Array[HitDiceSelectionButtonImplement] if interfaces ever work
func _get_breath_dice_button_implements() -> Array[HitDieSelectionButton]:
	var implements: Array[HitDieSelectionButton] = []
	implements.assign(_breath_dice_buttons.get_children())
	return implements
