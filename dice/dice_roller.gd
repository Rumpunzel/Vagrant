extends Node

signal die_rolled(die: Die)
signal save_rolled(save_result: SaveResult)

enum SaveOutcome {
	NORMAL,
	SUCCESS,
	FAILURE,
}

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


class SaveResult:
	var character: Character
	var attribute: CharacterAttribute
	var difficulty: int
	var dice: Array[Die]
	var highest_die: Die = null
	var save_outcome: SaveOutcome = SaveOutcome.NORMAL
	
	func _init(new_character: Character, new_attribute: CharacterAttribute, new_difficulty: int, new_dice: Array[Die]) -> void:
		character = new_character
		attribute = new_attribute
		difficulty = new_difficulty
		dice = new_dice
		for die: Die in dice:
			if highest_die == null or die.result > highest_die.result: highest_die = die
		if difficulty > 0:
			save_outcome = SaveOutcome.SUCCESS if highest_die != null and highest_die.result >= difficulty else SaveOutcome.FAILURE
