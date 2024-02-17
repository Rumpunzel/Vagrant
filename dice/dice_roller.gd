extends Node

signal die_rolled(die: Die)
signal save_rolled(save_result: SaveResult)

@export_group("Configuration")
@export var _dice_roll_sounds: AudioStreamPlayer

func roll_die(die: Die) -> Die:
	die.roll()
	die_rolled.emit(die)
	return die

func roll_sum(dice_pool: Array[Die]) -> int:
	var sum := 0
	for die: Die in dice_pool:
		sum += roll_die(die).result
	return sum

func roll_save(dice_pool: Array[Die], save_request: HitDiceSelection.SaveRequest) -> SaveResult:
	var character := save_request.character
	var attribute := save_request.attribute
	var attribute_score := character.get_attribute_score(attribute)
	for die: Die in dice_pool:
		die.roll_save(attribute_score)
	var save_result := SaveResult.new(character, attribute, save_request.difficulty, dice_pool)
	save_rolled.emit(save_result)
	return save_result

func generate_dice_pool(d4_amount: int, d6_amount: int, d8_amount: int, d10_amount: int, d12_amount: int) -> Array[Die]:
	var dice_pool: Array[Die] = [ ]
	dice_pool += Rules.d4.get_dice_pool(d4_amount)
	dice_pool += Rules.d6.get_dice_pool(d6_amount)
	dice_pool += Rules.d8.get_dice_pool(d8_amount)
	dice_pool += Rules.d10.get_dice_pool(d10_amount)
	dice_pool += Rules.d12.get_dice_pool(d12_amount)
	return dice_pool

func _on_die_rolled(_die: Die) -> void:
	pass#_play_dice_roll_sound()

func _on_save_rolled(_save_result: SaveResult) -> void:
	_play_dice_roll_sound()

func _play_dice_roll_sound() -> void:
	_dice_roll_sounds.play()
