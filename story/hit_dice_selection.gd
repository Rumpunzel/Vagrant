extends VBoxContainer

var _character: Character = null
var _attribute_to_roll: Character.Attributes
var _difficulty: int

func update_dice_selection(character: Character, attribute: Character.Attributes, difficulty: int, description: String) -> void:
	_character = character
	_attribute_to_roll = attribute
	_difficulty = difficulty
	var hit_dice := _character.hit_dice
	%d4Amount.update_dice_amount(hit_dice.get_dice_count(DiceRoller.Dice.d4))
	%d6Amount.update_dice_amount(hit_dice.get_dice_count(DiceRoller.Dice.d6))
	%d8Amount.update_dice_amount(hit_dice.get_dice_count(DiceRoller.Dice.d8))
	%d10Amount.update_dice_amount(hit_dice.get_dice_count(DiceRoller.Dice.d10))
	%d12Amount.update_dice_amount(hit_dice.get_dice_count(DiceRoller.Dice.d12))
	%Portrait.texture = character.portrait
	%Description.text = description

func _on_confirmed() -> void:
	var dice_to_roll := DicePool.new()
	for _i in range(%d4Amount.value):
		dice_to_roll.add_die(DiceRoller.Dice.d4)
	for _i in range(%d6Amount.value):
		dice_to_roll.add_die(DiceRoller.Dice.d6)
	for _i in range(%d8Amount.value):
		dice_to_roll.add_die(DiceRoller.Dice.d8)
	for _i in range(%d10Amount.value):
		dice_to_roll.add_die(DiceRoller.Dice.d10)
	for _i in range(%d12Amount.value):
		dice_to_roll.add_die(DiceRoller.Dice.d12)
	
	DiceRoller.roll_save(dice_to_roll, _character, _attribute_to_roll, _difficulty)
