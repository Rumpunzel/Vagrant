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

var result := 0
var highest_dice: Array[Die] = [ ]
var save_outcome: Outcome = Outcome.NORMAL

func _init(new_character: Character, new_attribute: CharacterAttribute, new_difficulty: int, new_dice: Array[Die]) -> void:
	character = new_character
	attribute = new_attribute
	difficulty = new_difficulty
	dice = new_dice
	
	for die: Die in dice:
		if die.result > result: result = die.result
	for die: Die in dice:
		if die.result == result:
			highest_dice.append(die)
	if difficulty > 0:
		save_outcome = Outcome.SUCCESS if result >= difficulty else Outcome.FAILURE
	
	var available_hit_dice := character.get_available_hit_dice()
	for hit_die: Die in available_hit_dice:
		hit_die.update_state()
