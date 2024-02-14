extends Node

signal die_rolled(die_result: DieResult)
signal save_rolled(dice_log_entry: DiceLogEntry)

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

var dice_log_entries: Array[DiceLogEntry] = [ ]

func roll_die(die: Dice) -> DieResult:
	var result := DieResult.new(die, randi_range(1, die))
	die_rolled.emit(result)
	return result

func roll_sum(dice_pool: DicePool) -> int:
	var sum := 0
	for die: Dice in dice_pool.dice:
		sum += roll_die(die).result
	return sum

func roll_save(dice_pool: DicePool, character: Character, attribute: Character.Attributes, difficulty: int = 0) -> DieResult:
	var attribute_score := character.get_attribute_score(attribute)
	var highest: DieResult = null
	var dice_results: Array[DieResult] = [ ]
	var exhausted_dice: Array[Dice] = [ ]
	
	for die: Dice in dice_pool.dice:
		var result := roll_die(die)
		if highest == null or result.result > highest.result: highest = result
		var save_outcome := DieOutcome.NORMAL if result.result <= attribute_score else DieOutcome.EXHAUSTED
		result.outcome = save_outcome
		dice_results.append(result)
		if save_outcome == DieOutcome.EXHAUSTED: exhausted_dice.append(die)
	
	for die: Dice in exhausted_dice:
		character.hit_dice.remove_die(die)
	
	var new_dice_log_entry := DiceLogEntry.new(character, attribute, highest, difficulty, dice_results)
	dice_log_entries.append(new_dice_log_entry)
	save_rolled.emit(new_dice_log_entry)
	return highest


class DiceLogEntry:
	var character: Character
	var attribute: Character.Attributes
	var result: DieResult
	var difficulty: int
	var dice: Array[DieResult]
	
	func _init(character: Character, attribute: Character.Attributes, result: DieResult, difficulty: int, dice: Array[DieResult]) -> void:
		self.character = character
		self.attribute = attribute
		self.result = result
		self.difficulty = difficulty
		self.dice = dice
	
	func get_save_outcome() -> SaveOutcome:
		return SaveOutcome.NORMAL if difficulty <= 0 else SaveOutcome.SUCCESS if result.result >= difficulty else SaveOutcome.FAILURE

class DieResult:
	var die: DiceRoller.Dice
	var result: int
	var outcome: DieOutcome
	
	func _init(die: Dice, result: int, outcome: DieOutcome = DieOutcome.NORMAL) -> void:
		self.die = die
		self.result = result
		self.outcome = outcome
