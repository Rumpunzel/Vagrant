class_name SaveResult

enum Outcome {
	NORMAL,
	SUCCESS,
	FAILURE,
}

var character: Character
var attribute: CharacterAttribute
var difficulty: int
var dice: Array[Die]

var highest_die: Die = null
var save_outcome: Outcome = Outcome.NORMAL

func _init(new_character: Character, new_attribute: CharacterAttribute, new_difficulty: int, new_dice: Array[Die]) -> void:
	character = new_character
	attribute = new_attribute
	difficulty = new_difficulty
	dice = new_dice
	for die: Die in dice:
		if highest_die == null or die.result > highest_die.result: highest_die = die
	if difficulty > 0:
		save_outcome = Outcome.SUCCESS if highest_die != null and highest_die.result >= difficulty else Outcome.FAILURE
