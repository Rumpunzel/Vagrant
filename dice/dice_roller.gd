extends Node

signal die_rolled(die_result: DieResult)
signal save_rolled(save_result: SaveResult)

enum Dice {
	d4 = 4,
	d6 = 6,
	d8 = 8,
	d10 = 10,
	d12 = 12,
	d20 = 20,
}

enum DieOutcome {
	NORMAL,
	EXHAUSTED,
}

enum SaveOutcome {
	NORMAL,
	SUCCESS,
	FAILURE,
}

var die_results: Array[DieResult] = [ ]
var save_results: Array[SaveResult] = [ ]

func roll_die(die: Dice) -> DieResult:
	var die_result := DieResult.new(die, randi_range(1, die))
	die_results.append(die_result)
	die_rolled.emit(die_result)
	return die_result

func roll_sum(dice_pool: DicePool) -> int:
	var sum := 0
	for die: Dice in dice_pool.dice:
		sum += roll_die(die).result
	return sum

func roll_save(dice_pool: DicePool, save_request: HitDiceSelection.SaveRequest) -> SaveResult:
	var character := save_request.character
	var attribute := save_request.attribute
	var attribute_score := character.get_attribute_score(attribute)
	var highest_result: DieResult = null
	var dice_results: Array[DieResult] = [ ]
	var exhausted_dice: Array[Dice] = [ ]
	
	for die: Dice in dice_pool.dice:
		var result := roll_die(die)
		if highest_result == null or result.result > highest_result.result: highest_result = result
		var save_outcome := DieOutcome.NORMAL if result.result <= attribute_score else DieOutcome.EXHAUSTED
		result.outcome = save_outcome
		dice_results.append(result)
		if save_outcome == DieOutcome.EXHAUSTED: exhausted_dice.append(die)
	
	for die: Dice in exhausted_dice:
		character.hit_dice.remove_die(die)
	
	var save_result := SaveResult.new(character, attribute, highest_result, save_request.difficulty, dice_results)
	save_results.append(save_result)
	save_rolled.emit(save_result)
	return save_result


class SaveResult:
	var character: Character
	var attribute: CharacterAttribute
	var result: DieResult
	var difficulty: int
	var dice: Array[DieResult]
	
	func _init(new_character: Character, new_attribute: CharacterAttribute, new_result: DieResult, new_difficulty: int, new_dice: Array[DieResult]) -> void:
		character = new_character
		attribute = new_attribute
		result = new_result
		difficulty = new_difficulty
		dice = new_dice
	
	func get_save_outcome() -> SaveOutcome:
		return SaveOutcome.NORMAL if difficulty <= 0 else SaveOutcome.SUCCESS if result.result >= difficulty else SaveOutcome.FAILURE

class DieResult:
	var die: DiceRoller.Dice
	var result: int
	var outcome: DieOutcome
	
	func _init(new_die: Dice, new_result: int, new_outcome: DieOutcome = DieOutcome.NORMAL) -> void:
		die = new_die
		result = new_result
		outcome = new_outcome
