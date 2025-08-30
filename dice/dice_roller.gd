@tool
extends Node

signal die_rolled(die: Die)
signal save_rolled(save_result: SaveResult)

func roll_die(die: Die, play_sound: bool = true) -> Die:
	die.roll(play_sound)
	die_rolled.emit(die)
	return die

func roll_dice(dice_pool: Array[Die], play_sound: bool = true) -> Array[Die]:
	for die: Die in dice_pool:
		roll_die(die, play_sound)
	return dice_pool

func roll_sum(dice_pool: Array[Die], play_sound: bool = true) -> int:
	var sum: int = 0
	for die: Die in dice_pool:
		sum += roll_die(die, play_sound).result
	return sum

func roll_attribute() -> BaseAttributeScore:
	var rolled_dice: Array[Die] = DiceRoller.roll_dice(Rules.d6.get_dice_pool(2))
	return BaseAttributeScore.create(rolled_dice)

func roll_save(dice_pool: Array[Die], save_request: SaveRequest) -> SaveResult:
	var character: Character = save_request.character
	var attribute: CharacterAttribute = save_request.attribute
	var attribute_score: AttributeScore = character.get_attribute_score(attribute)
	for die: Die in dice_pool: die.roll_save(attribute_score.get_score())
	var save_result: SaveResult = SaveResult.new(character, attribute, save_request.difficulty)
	save_rolled.emit(save_result)
	return save_result

func generate_dice_pool(dice: Dictionary[DieType, int]) -> Array[Die]:
	var dice_pool: Array[Die] = [ ]
	for die_type: DieType in dice:
		dice_pool += die_type.get_dice_pool(dice[die_type])
	return dice_pool
