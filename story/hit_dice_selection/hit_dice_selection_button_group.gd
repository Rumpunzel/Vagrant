@tool
class_name HitDiceSelectionButtonGroup
extends HitDiceSelectionButtonImplement

@export var breath_die_type: DieType :
	set(new_breath_die_type):
		breath_die_type = new_breath_die_type
		_all_button.text = "%s" % breath_die_type

@export_group("Configuration")
@export var _buttons: Container
@export var _all_button: DisplayButton
@export var _breath_die_selection_button: PackedScene

func update_breath_dice(available_breath_dice: Array[BreathDie], save_result: SaveResult = null) -> void:
	var all_buttons_auto_selected: bool = true
	var relevant_breath_dice: Array[BreathDie] = [ ]
	for die: BreathDie in available_breath_dice:
		if die.die_type == breath_die_type: relevant_breath_dice.append(die)
	for button: HitDieSelectionButton in _get_breath_die_selection_buttons():
		button.toggled.disconnect(_on_button_toggled)
		#button.changed_disabled.disconnect(_on_button_changed_disabled)
		button.activation_changed.disconnect(_on_button_activation_changed)
		_buttons.remove_child(button)
		button.queue_free()
	
	for breath_die: BreathDie in relevant_breath_dice:
		var button: HitDieSelectionButton = _breath_die_selection_button.instantiate()
		_buttons.add_child(button)
		button.breath_die = breath_die
		print(save_result)
		button.update_save_result(save_result)
		#all_buttons_auto_selected = all_buttons_auto_selected and breath_die.is_selected()
		button.toggled.connect(_on_button_toggled)
		#button.changed_disabled.connect(_on_button_changed_disabled)
		button.activation_changed.connect(_on_button_activation_changed)
	
	_on_button_toggled()
	_on_button_changed_disabled()
	_on_button_activation_changed()
	visible = not relevant_breath_dice.is_empty()
	_all_button.visible = relevant_breath_dice.size() > 1

func update_save_request(save_request: SaveRequest) -> void:
	pass

func update_save_result(save_result: SaveResult) -> void:
	update_breath_dice(save_result.get_breath_dice(), save_result)

func select() -> void:
	_all_button.set_pressed_no_signal(true)
	for button: HitDieSelectionButton in _get_breath_die_selection_buttons():
		button.select()

func deselect() -> void:
	_all_button.set_pressed_no_signal(false)
	for button: HitDieSelectionButton in _get_breath_die_selection_buttons():
		button.deselect()

func disable() -> void:
	for button: HitDieSelectionButton in _get_breath_die_selection_buttons():
		button.active = false

func _get_breath_die_selection_buttons() -> Array[Node]:
	return _buttons.get_children()

func _on_button_toggled(_toggled_on: bool = false) -> void:
	var all_buttons_selected: bool = true
	for button: HitDieSelectionButton in _get_breath_die_selection_buttons():
		all_buttons_selected = all_buttons_selected and button.button_pressed
	_all_button.set_pressed_no_signal(all_buttons_selected)

func _on_button_changed_disabled(_disabled: bool = false) -> void:
	var all_buttons_disabled: bool = true
	for button: HitDieSelectionButton in _get_breath_die_selection_buttons():
		all_buttons_disabled = all_buttons_disabled and button.disabled
	_all_button.disabled = all_buttons_disabled

func _on_button_activation_changed(_new_status: bool = false) -> void:
	var all_buttons_active: bool = true
	for button: HitDieSelectionButton in _get_breath_die_selection_buttons():
		all_buttons_active = all_buttons_active and button.active
	_all_button.active = all_buttons_active
