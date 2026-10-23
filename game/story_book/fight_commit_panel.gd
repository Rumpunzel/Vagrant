class_name FightCommitPanel
extends VBoxContainer

## Where the player commits at the start of an exchange: the weapon die to strike with and whether to raise the shield

signal committed(weapon_die: Die, raises_shield: bool)

var _weapon_die: Die
var _shield_switch: CheckButton

func setup(fight: Fight, step: CommitStep) -> void:
	var side: FightSide = step.get_side(fight)
	_weapon_die = step.get_default_weapon_die(fight)
	var roll: Label = Label.new()
	roll.text = step.describe_roll(fight)
	roll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(roll)
	if step.has_weapon_choice(fight):
		var group: ButtonGroup = ButtonGroup.new()
		for die: Die in side.weapon_dice: _add_weapon_option(CommitStep.describe_weapon_die(side, die), die, group)
		_add_weapon_option("Hold back.", null, group)
	if step.has_shield_choice(fight):
		_shield_switch = CheckButton.new()
		_shield_switch.text = step.describe_shield(fight)
		_shield_switch.button_pressed = side.get_shield_overshoot() == 0
		add_child(_shield_switch)
	var strike: Button = Button.new()
	strike.text = "Strike!"
	strike.pressed.connect(self.strike)
	add_child(strike)

## Commits to what is selected
func strike() -> void: committed.emit(_weapon_die, _shield_switch != null and _shield_switch.button_pressed)

func _add_weapon_option(description: String, die: Die, group: ButtonGroup) -> void:
	var option: CheckBox = CheckBox.new()
	option.text = description
	option.button_group = group
	option.button_pressed = die == _weapon_die
	option.toggled.connect(func(toggled_on: bool) -> void:
		if toggled_on: _weapon_die = die
	)
	add_child(option)
