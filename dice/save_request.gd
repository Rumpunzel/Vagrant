class_name SaveRequest

var character: Character
var attribute: CharacterAttribute
var difficulty: int
var description: String

func _init(new_character: Character, new_attribute: CharacterAttribute, new_difficulty: int, new_description: String) -> void:
	character = new_character
	attribute = new_attribute
	difficulty = new_difficulty
	description = new_description
	
	var available_hit_dice: Array[Die] = character.get_available_hit_dice()
	for hit_die: Die in available_hit_dice:
		var attribute_score: AttributeScore = character.get_attribute_score(attribute)
		hit_die.update_state(attribute_score)
