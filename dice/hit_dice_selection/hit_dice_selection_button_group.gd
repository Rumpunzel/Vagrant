class_name HitDiceSelectionButtonGroup
extends VBoxContainer

@export var hit_die_type: DieType :
	set(new_hit_die_type):
		hit_die_type = new_hit_die_type
		_all_button.text = "%s" % hit_die_type

@export_group("Configuration")
@export var _buttons: Container
@export var _all_button: Button
@export var _hit_die_selection_button: PackedScene

func update_hit_dice(available_hit_dice: Array[Die], display_results: HitDieSelectionButton.DisplayResults, save_difficulty := 0) -> void:
	var all_buttons_auto_selected := true
	var relevant_hit_dice: Array[Die] = [ ]
	for die: Die in available_hit_dice:
		if die.die_type == hit_die_type: relevant_hit_dice.append(die)
	for button: HitDieSelectionButton in _get_hit_die_selection_buttons():
		button.toggled.disconnect(_on_button_toggled)
		button.changed_disabled.disconnect(_on_button_changed_disabled)
		button.changed_button_mask.disconnect(_on_button_changed_button_mask)
		_buttons.remove_child(button)
		button.queue_free()
	
	for hit_die: Die in relevant_hit_dice:
		var button: HitDieSelectionButton = _hit_die_selection_button.instantiate()
		button.die = hit_die
		button.display_results = display_results
		button.save_difficulty = save_difficulty
		all_buttons_auto_selected = all_buttons_auto_selected and hit_die.is_selected()
		button.toggled.connect(_on_button_toggled)
		button.changed_disabled.connect(_on_button_changed_disabled)
		button.changed_button_mask.connect(_on_button_changed_button_mask)
		_buttons.add_child(button)
	
	_on_button_toggled()
	_on_button_changed_disabled()
	_on_button_changed_button_mask()
	visible = not relevant_hit_dice.is_empty()

func select_all_available_buttons(select_buttons := true) -> void:
	_all_button.set_pressed_no_signal(select_buttons)
	for button: HitDieSelectionButton in _get_hit_die_selection_buttons():
		if not button.disabled: button.button_pressed = select_buttons

func disable_buttons(set_to_disabled := true) -> void:
	for button: HitDieSelectionButton in _get_hit_die_selection_buttons():
		button.disable(set_to_disabled)

func get_selected_dice() -> Array[Die]:
	var selected_dice: Array[Die] = [ ]
	for button: HitDieSelectionButton in _get_hit_die_selection_buttons():
		if button.button_pressed: selected_dice.append(button.die)
	return selected_dice

func _get_hit_die_selection_buttons() -> Array[Node]:
	return _buttons.get_children()

func _on_button_toggled(_toggled_on := false) -> void:
	var all_buttons_selected := true
	for button: HitDieSelectionButton in _get_hit_die_selection_buttons():
		all_buttons_selected = all_buttons_selected and button.button_pressed
	_all_button.set_pressed_no_signal(all_buttons_selected)

func _on_button_changed_disabled(_disabled := false) -> void:
	var all_buttons_disabled := true
	for button: HitDieSelectionButton in _get_hit_die_selection_buttons():
		all_buttons_disabled = all_buttons_disabled and button.disabled
	_all_button.disabled = all_buttons_disabled

func _on_button_changed_button_mask(_button_mask := 0) -> void:
	var joined_button_mask := 0
	for button: HitDieSelectionButton in _get_hit_die_selection_buttons():
		joined_button_mask = joined_button_mask | button.button_mask
	_all_button.button_mask = joined_button_mask
