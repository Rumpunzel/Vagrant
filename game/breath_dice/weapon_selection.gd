class_name WeaponSelection
extends VBoxContainer

## Lets the player pick the weapon for a fight exchange (or none) and shows every face of each weapon die.

var _fight_request: FightRequest
var _buttons: Array[Button] = []

func setup(fight_request: FightRequest) -> void:
	_fight_request = fight_request
	_clear()
	var button_group: ButtonGroup = ButtonGroup.new()
	_add_option(null, button_group)
	for weapon: Weapon in fight_request.character.weapons: _add_option(weapon, button_group)
	_add_choose_die_option()

func get_option_count() -> int: return _buttons.size()

## Picks option [param index] like a click would; 0 is unarmed
func press(index: int) -> void:
	_buttons[index].button_pressed = true

## What it shows, as data ([PageRecord]): each option as shown and which was picked
func get_record() -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	for child: Node in get_children():
		if child is CheckBox: rows.append({check = (child as CheckBox).text, pressed = (child as CheckBox).button_pressed})
		elif child is HBoxContainer:
			var button: Button = child.get_child(0)
			var faces: String = (child.get_child(1) as RichTextLabel).text if child.get_child_count() > 1 else ""
			rows.append({text = button.text, faces = faces, disabled = button.disabled, pressed = button.button_pressed})
	return rows

func show_record(rows: Array) -> void:
	_clear()
	var button_group: ButtonGroup = ButtonGroup.new()
	for row: Dictionary in rows:
		if row.has("check"):
			var check_box: CheckBox = CheckBox.new()
			check_box.text = row.check
			check_box.button_pressed = row.pressed
			add_child(check_box)
		else:
			var text: String = row.text
			var faces: String = row.faces
			var disabled: bool = row.disabled
			var pressed: bool = row.pressed
			_add_row(text, faces, disabled, pressed, button_group)

func _clear() -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_buttons.clear()

func _add_option(weapon: Weapon, button_group: ButtonGroup) -> void:
	var text: String = "Unarmed" if not weapon else "%s (%s)" % [weapon.get_equipment_name(), weapon.get_die_type()]
	var faces: String = Inventory.describe_faces(weapon) if weapon else ""
	var button: Button = _add_row(text, faces, weapon != null and not weapon.is_usable(), weapon == _fight_request.selected_weapon, button_group)
	button.toggled.connect(_on_option_toggled.bind(weapon))

func _add_row(text: String, faces_text: String, disabled: bool, pressed: bool, button_group: ButtonGroup) -> Button:
	var row: HBoxContainer = HBoxContainer.new()
	var button: Button = Button.new()
	button.toggle_mode = true
	button.button_group = button_group
	button.text = text
	button.disabled = disabled
	button.button_pressed = pressed
	row.add_child(button)
	if not faces_text.is_empty():
		var faces: RichTextLabel = RichTextLabel.new()
		faces.bbcode_enabled = true
		faces.fit_content = true
		faces.autowrap_mode = TextServer.AUTOWRAP_OFF
		faces.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		faces.text = faces_text
		row.add_child(faces)
	add_child(row)
	_buttons.append(button)
	return button

func _on_option_toggled(toggled_on: bool, weapon: Weapon) -> void:
	if toggled_on: _fight_request.selected_weapon = weapon

## With several weapon dice (Veteran), the player may ask to pick the die even when none needs forcing
func _add_choose_die_option() -> void:
	var extra_dice: int = 0
	for ability: Ability in _fight_request.character.character_profile.get_abilities(): extra_dice += ability.get_extra_weapon_dice()
	if extra_dice == 0: return
	var check_box: CheckBox = CheckBox.new()
	check_box.text = "Choose the weapon die myself"
	check_box.button_pressed = _fight_request.always_choose_weapon_die
	check_box.toggled.connect(func(pressed: bool) -> void: _fight_request.always_choose_weapon_die = pressed)
	add_child(check_box)
