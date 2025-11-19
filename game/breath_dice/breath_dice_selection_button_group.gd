@tool
class_name BreathDiceSelectionButtonGroup
extends BreathDiceGroup

@export_group("Configuration")
@export var _exhaustion: TextureRect
@export var _all_button: DisplayButton

func _ready() -> void:
	die_type_changed.connect(_on_die_type_changed)
	breath_die_button_added.connect(_on_breath_die_button_added)

func set_breath_dice(new_breath_dice: Array[BreathDie]) -> void:
	super.set_breath_dice(new_breath_dice)
	_all_button.visible = breath_dice.size() > 1

func set_exhaustion(exhaustion: Array[DieType]) -> void:
	_exhaustion.visible = exhaustion.has(die_type)

func update_dice_request(dice_request: DiceRequest) -> void:
	for button: BreathDieSelectionButton in get_elements(): button.current_dice_request = dice_request
	_all_button.active = true

func select_all() -> void:
	for button: BreathDieSelectionButton in get_elements(): button.select()
	_all_button.set_pressed_no_signal(true)

func deselect_all() -> void:
	for button: BreathDieSelectionButton in get_elements(): button.deselect()
	_all_button.set_pressed_no_signal(false)

func deactivate(reset_on_deactivation: bool) -> void:
	for button: BreathDieSelectionButton in get_elements(): button.deactivate(reset_on_deactivation)
	_all_button.active = false
	_all_button.disabled = true

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
