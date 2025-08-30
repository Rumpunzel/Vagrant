class_name SaveResult

enum Outcome {
	NORMAL,
	SUCCESS,
	FAILURE,
}

var character: Character
var attribute: CharacterAttribute
var difficulty: int

var dice: Array[Die] = []
var result: int = 0
var highest_dice: Array[Die] = [ ]
var save_outcome: Outcome = Outcome.NORMAL

func _init(new_character: Character, new_attribute: CharacterAttribute, new_difficulty: int) -> void:
	character = new_character
	attribute = new_attribute
	difficulty = new_difficulty
	
	# Make a snapshot of the breath dice
	dice.assign(character.hit_dice.map(func(die: Die) -> Die: return die.duplicate()))
	
	for die: Die in dice: if die.result > result: result = die.result
	for die: Die in dice: if die.result == result: highest_dice.append(die)
	if difficulty > 0: save_outcome = Outcome.SUCCESS if result >= difficulty else Outcome.FAILURE
	
	for hit_die: Die in character.hit_dice: hit_die.deselect()

func get_die_color(die: Die) -> Color:
	var color: Color = Color.WHITE
	match save_outcome:
		Outcome.NORMAL: pass
		Outcome.SUCCESS: color = Color.LIME_GREEN if die.is_alive() else Color.CORNFLOWER_BLUE
		Outcome.FAILURE: color = Color.ORANGE if die.is_alive() else Color.FIREBRICK
	return color
