@tool
extends Node

signal die_rolled(die: Die)

func roll_die(die: Die, play_sound: bool = true) -> Die:
	die.roll(play_sound)
	die_rolled.emit(die)
	return die

func roll_dice(dice_pool: Array[Die], play_sound: bool = true) -> Array[Die]:
	for die: Die in dice_pool: roll_die(die, play_sound)
	return dice_pool

func roll_attribute() -> RolledAttributeScore:
	var rolled_dice: Array[Die] = roll_dice(Rules.d6.get_dice_pool(2))
	return RolledAttributeScore.new(rolled_dice)

func generate_dice_pool(dice: Dictionary[DieType, int]) -> Array[Die]:
	var dice_pool: Array[Die] = [ ]
	for die_type: DieType in dice: dice_pool += die_type.get_dice_pool(dice[die_type])
	return dice_pool
