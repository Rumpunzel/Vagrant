@tool
class_name BreathDiceSelectionButtons
extends PanelContainer

enum Direction {
	Horizontal,
	Vertical,
}

@export_range(0.0, 256.0, 1.0, "exp", "suffix:px") var _button_size: float = 64.0
@export var _direction: Direction = Direction.Horizontal :
	set(new_direction):
		_direction = new_direction
		if _breath_dice_buttons:
			_breath_dice_buttons_parent.remove_child(_breath_dice_buttons)
			_breath_dice_buttons.queue_free()
		match _direction:
			Direction.Horizontal: _breath_dice_buttons = HBoxContainer.new()
			Direction.Vertical: _breath_dice_buttons = VBoxContainer.new()
			_: assert(false, "Does not exist")
		_breath_dice_buttons_parent.add_child(_breath_dice_buttons)

@export_group("Configuration")
@export var _breath_dice_buttons_parent: Container
@export var _breath_dice_selection_group: PackedScene

var _breath_dice_buttons: BoxContainer
var _button_groups: Dictionary[DieType, BreathDiceSelectionButtonGroup] = {}

func _ready() -> void:
	if not Engine.is_editor_hint(): return
	var debug_dice_pool: Dictionary[DieType, int] = {
		Rules.d4: 1,
		Rules.d6: 1,
		Rules.d8: 1,
		Rules.d10: 1,
		Rules.d12: 1,
	}
	var debug_breath_dice: Array[BreathDie] = DiceRoller.generate_breath_dice_pool(debug_dice_pool)
	setup_breath_dice(debug_breath_dice)

func setup_breath_dice(breath_dice: Array[BreathDie]) -> void:
	_button_groups.clear()
	_clear()
	for breath_die: BreathDie in breath_dice:
		var button_group: BreathDiceSelectionButtonGroup = _button_groups.get(breath_die.die_type)
		if not button_group:
			button_group = _breath_dice_selection_group.instantiate()
			button_group.breath_die_type = breath_die.die_type
			_button_groups[breath_die.die_type] = button_group
			_breath_dice_buttons.add_child(button_group)
			match _direction:
				Direction.Horizontal: pass
				Direction.Vertical: _breath_dice_buttons.move_child(button_group, 0)
				_: assert(false, "Does not exist")
		button_group.add_button(breath_die, _button_size)

func update_save_request(save_request: SaveRequest) -> void:
	for button_group: BreathDiceSelectionButtonGroup in _get_button_groups():
		button_group.update_save_request(save_request)

func update_save_result(save_result: SaveResult) -> void:
	for button_group: BreathDiceSelectionButtonGroup in _get_button_groups():
		button_group.update_save_result(save_result)

func select_all(selected: bool = true) -> void:
	for button_group: BreathDiceSelectionButtonGroup in _get_button_groups():
		if selected: button_group.select_all()
		else: button_group.deselect_all()

func disable_buttons() -> void:
	for button_group: BreathDiceSelectionButtonGroup in _get_button_groups():
		button_group.disable()

func _clear() -> void:
	if not _breath_dice_buttons:
		_direction = _direction
		return
	for child: Node in _breath_dice_buttons.get_children():
		_breath_dice_buttons.remove_child(child)
		child.queue_free()

func _get_button_groups() -> Array[BreathDiceSelectionButtonGroup]:
	var button_groups: Array[BreathDiceSelectionButtonGroup] = []
	button_groups.assign(_breath_dice_buttons.get_children())
	return button_groups
