@tool
class_name BreathDiceSelectionButtonGroup
extends FlexContainer

@export var breath_die_type: DieType :
	set(new_breath_die_type):
		breath_die_type = new_breath_die_type
		_all_button.text = "%s" % breath_die_type

@export_group("Configuration")
@export var _all_button: DisplayButton
@export var _breath_die_selection_button: PackedScene

func add_button(breath_die: BreathDie) -> void:
	var button: BreathDieSelectionButton = _breath_die_selection_button.instantiate()
	button.breath_die = breath_die
	button.toggled.connect(_on_button_toggled)
	_all_button.visible = not _get_buttons().is_empty()
	add(button)

func update_dice_request(dice_request: DiceRequest) -> void:
	_all_button.active = true
	for button: BreathDieSelectionButton in _get_buttons(): button.update_dice_request(dice_request)

func update_save_result(save_result: SaveResult) -> void:
	for button: BreathDieSelectionButton in _get_buttons(): button.update_save_result(save_result)

func update_fight_result(fight_result: FightResult) -> void:
	for button: BreathDieSelectionButton in _get_buttons(): button.update_fight_result(fight_result)

func select_all() -> void:
	_all_button.set_pressed_no_signal(true)
	for button: BreathDieSelectionButton in _get_buttons(): button.select()

func deselect_all() -> void:
	_all_button.set_pressed_no_signal(false)
	for button: BreathDieSelectionButton in _get_buttons(): button.deselect()

func disable() -> void:
	_all_button.active = false
	_all_button.disabled = true
	for button: BreathDieSelectionButton in _get_buttons(): button.disable()

func _get_buttons() -> Array[BreathDieSelectionButton]:
	var buttons: Array[BreathDieSelectionButton] = []
	buttons.assign(_box_container.get_children())
	return buttons

func _on_button_toggled(_toggled_on: bool = false) -> void:
	var all_buttons_selected: bool = true
	for button: BreathDieSelectionButton in _get_buttons():
		all_buttons_selected = all_buttons_selected and button.button_pressed
	_all_button.set_pressed_no_signal(all_buttons_selected)

func _on_all_button_toggled(toggled_on: bool) -> void:
	if toggled_on: for button: BreathDieSelectionButton in _get_buttons(): button.select()
	else: for button: BreathDieSelectionButton in _get_buttons(): button.deselect()
