class_name WeaponSelection
extends VBoxContainer

## Lets the player pick the weapon for a fight exchange (or none) and shows every face of each
## weapon die: marked faces are struck through, ruined weapons can't be picked.
## Deliberately plain; meant to be reworked by hand.

var _fight_request: FightRequest
var _buttons: Array[Button] = []

func setup(fight_request: FightRequest) -> void:
	_fight_request = fight_request
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	_buttons.clear()
	var button_group: ButtonGroup = ButtonGroup.new()
	_add_option(null, button_group)
	for weapon: Weapon in fight_request.character.weapons: _add_option(weapon, button_group)

func get_option_count() -> int: return _buttons.size()

## Picks option [param index] like a click would; 0 is unarmed
func press(index: int) -> void:
	_buttons[index].button_pressed = true

func _add_option(weapon: Weapon, button_group: ButtonGroup) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	var button: Button = Button.new()
	button.toggle_mode = true
	button.button_group = button_group
	button.text = "Unarmed" if not weapon else "%s (%s)" % [weapon.get_weapon_name(), weapon.get_die_type()]
	button.disabled = weapon != null and not weapon.is_usable()
	button.button_pressed = weapon == _fight_request.selected_weapon
	button.toggled.connect(_on_option_toggled.bind(weapon))
	row.add_child(button)
	if weapon:
		var faces: RichTextLabel = RichTextLabel.new()
		faces.bbcode_enabled = true
		faces.fit_content = true
		faces.autowrap_mode = TextServer.AUTOWRAP_OFF
		faces.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		faces.text = _describe_faces(weapon)
		row.add_child(faces)
	add_child(row)
	_buttons.append(button)

func _on_option_toggled(toggled_on: bool, weapon: Weapon) -> void:
	if toggled_on: _fight_request.selected_weapon = weapon

static func _describe_faces(weapon: Weapon) -> String:
	var faces: Array[String] = []
	for face: int in range(1, weapon.get_die_type().faces + 1):
		if weapon.is_marked(face): faces.append("[color=#%s][s]%d[/s][/color]" % [Main.FAILURE.to_html(), face])
		else: faces.append("%d" % face)
	var description: String = " ".join(faces)
	if not weapon.is_usable(): description = "[color=gray]%s — ruined[/color]" % description
	return description
