@tool
class_name BreathDiceSelectionButtonGroup
extends BreathDiceGroup

@export_group("Configuration")
@export var _all_button: DisplayButton

func _ready() -> void:
	die_type_changed.connect(_on_die_type_changed)
	breath_die_button_added.connect(_on_breath_die_button_added)

func setup_breath_dice(breath_dice: Array[BreathDie]) -> void:
	super.setup_breath_dice(breath_dice)
	_all_button.visible = breath_dice.size() > 1

func update_dice_request(dice_request: DiceRequest) -> void:
	_all_button.active = true
	for button: BreathDieSelectionButton in get_elements(): button.update_dice_request(dice_request)

func update_save_result(save_result: SaveResult) -> void:
	for button: BreathDieSelectionButton in get_elements(): button.update_save_result(save_result)

func update_fight_result(fight_result: FightResult) -> void:
	for button: BreathDieSelectionButton in get_elements(): button.update_fight_result(fight_result)

func select_all() -> void:
	_all_button.set_pressed_no_signal(true)
	for button: BreathDieSelectionButton in get_elements(): button.select()

func deselect_all() -> void:
	_all_button.set_pressed_no_signal(false)
	for button: BreathDieSelectionButton in get_elements(): button.deselect()

func deactivate() -> void:
	_all_button.active = false
	_all_button.disabled = true
	for button: BreathDieSelectionButton in get_elements(): button.deactivate()

func _on_button_toggled(_toggled_on: bool = false) -> void:
	var all_buttons_selected: bool = true
	for button: BreathDieSelectionButton in get_elements():
		all_buttons_selected = all_buttons_selected and button.button_pressed
	_all_button.set_pressed_no_signal(all_buttons_selected)

func _on_all_button_toggled(toggled_on: bool) -> void:
	if toggled_on: for button: BreathDieSelectionButton in get_elements(): button.select()
	else: for button: BreathDieSelectionButton in get_elements(): button.deselect()

func _on_die_type_changed(_die_typ: DieType) -> void:
	_all_button.text = "%s" % die_type

func _on_breath_die_button_added(breath_die_button: BreathDieSelectionButton) -> void:
	breath_die_button.toggled.connect(_on_button_toggled)
