class_name CharacterAttributes
extends Resource

# CharacterAttribute -> int
signal attribute_scores_changed(attribute_scores: Dictionary)

const STRENGTH: CharacterAttribute = preload("res://characters/attributes/strength.tres")
const AGILITY: CharacterAttribute = preload("res://characters/attributes/agility.tres")
const CONSTITUTION: CharacterAttribute = preload("res://characters/attributes/constitution.tres")
const INTELLIGENCE: CharacterAttribute = preload("res://characters/attributes/intelligence.tres")
const WILL: CharacterAttribute = preload("res://characters/attributes/will.tres")
const CHARISMA: CharacterAttribute = preload("res://characters/attributes/charisma.tres")

const ALL: Array[CharacterAttribute] = [
	STRENGTH,
	AGILITY,
	CONSTITUTION,
	INTELLIGENCE,
	WILL,
	CHARISMA,
]

# CharacterAttribute -> int
@export var _attribute_scores: Dictionary = {
	STRENGTH: 0,
	AGILITY: 0,
	CONSTITUTION: 0,
	INTELLIGENCE: 0,
	WILL: 0,
	CHARISMA: 0,
}

func initialize_attributes(starting_attributes: CharacterAttributes) -> void:
	for attribute: CharacterAttribute in CharacterAttributes.ALL:
		var attribute_score := 0
		if starting_attributes != null:
			attribute_score = starting_attributes.get_attribute_score(attribute)
		if attribute_score == 0:
			attribute_score = DiceRoller.roll_sum(DicePool.get_2d6())
		_attribute_scores[attribute] = attribute_score
	attribute_scores_changed.emit(_attribute_scores)

func get_attribute_score(attribute: CharacterAttribute) -> int:
	return _attribute_scores.get(attribute, 0)

func _to_string() -> String:
	var result := ""
	for attribute: CharacterAttribute in _attribute_scores.keys():
		result += "%s: %d\n" % [attribute, _attribute_scores[attribute]]
	return result
