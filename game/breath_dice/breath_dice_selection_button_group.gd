@tool
class_name BreathDiceSelectionButtonGroup
extends BreathDiceGroup

@export_group("Configuration")
@export var _exhaustion_icon: TextureRect
@export var _all_button: DisplayButton

func _ready() -> void:
	die_type_changed.connect(_on_die_type_changed)
	breath_die_button_added.connect(_on_breath_die_button_added)

func update_dice_request(dice_request: DiceRequest) -> void:
	for button: BreathDieSelectionButton in get_elements(): button.current_dice_request = dice_request
	_all_button.active = true

func select_all() -> void:
	for button: BreathDieSelectionButton in get_elements(): button.select()
	_all_button.set_pressed_no_signal(true)

func deselect_all() -> void:
	for button: BreathDieSelectionButton in get_elements(): button.deselect()
	_all_button.set_pressed_no_signal(false)

func update_results(dice_result: DiceRequestResult) -> void:
	var index: int = 0
	for breath_die: Die in dice_result.dice:
		if breath_die.die_type != _die_type: continue
		assert(index < _breath_dice_count)
		var button: BreathDieSelectionButton = get_elements()[index]
		button.update_result(breath_die.result)
		index += 1

func update_colors(dice_result: DiceRequestResult) -> void:
	var breath_dice: Array[Die] = dice_result.dice
	var index: int = 0
	for breath_die: Die in breath_dice:
		if breath_die.die_type != _die_type: continue
		assert(index < _breath_dice_count)
		var button: BreathDieSelectionButton = get_elements()[index]
		button.update_state(dice_result, breath_die)
		index += 1

func deactivate() -> void:
	for button: BreathDieSelectionButton in get_elements(): button.deactivate()
	_all_button.active = false
	_all_button.disabled = true

func _update_visibility() -> void:
	for button: BreathDieSelectionButton in get_elements():
		if is_exhausted(): button.set_icon_colors(Main.FAILURE)
		else: button.remove_icon_colors()
	_exhaustion_icon.visible = is_exhausted() and _breath_dice_count <= 0
	_all_button.visible = _breath_dice_count > 1

func _on_button_toggled(_toggled_on: bool = false) -> void:
	var all_buttons_selected: bool = true
	for button: BreathDieSelectionButton in get_elements():
		all_buttons_selected = all_buttons_selected and button.button_pressed
	_all_button.set_pressed_no_signal(all_buttons_selected)

func _on_all_button_toggled(toggled_on: bool) -> void:
	if toggled_on: for button: BreathDieSelectionButton in get_elements(): button.select()
	else: for button: BreathDieSelectionButton in get_elements(): button.deselect()

func _on_die_type_changed(_die_typ: DieType) -> void:
	_all_button.text = "%s" % _die_type

func _on_breath_die_button_added(breath_die_button: BreathDieSelectionButton) -> void:
	breath_die_button.toggled.connect(_on_button_toggled)
