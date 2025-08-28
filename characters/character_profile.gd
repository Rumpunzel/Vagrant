class_name CharacterProfile
extends Resource

@export_placeholder("Name") var name: String
@export var portrait: Texture2D = preload("res://assets/portraits/knight.jpeg")

## The character's attribute scores. Will be rolled with 2d6 if null.
@export var attribute_scores: Dictionary[CharacterAttribute, AttributeScore] = {
	Rules.STRENGTH: null,
	Rules.AGILITY: null,
	Rules.INTELLIGENCE: null,
}
@export var test: AttributeScore

@export var _breath_dice: Dictionary[DieType, int] = {
	Rules.d4: 1,
	Rules.d6: 1,
	Rules.d8: 1,
	Rules.d10: 1,
	Rules.d12: 1,
}

func _init(new_name: String, new_portrait: Texture2D, new_attribute_scores: Dictionary[CharacterAttribute, AttributeScore]) -> void:
	name = new_name
	portrait = new_portrait
	attribute_scores = new_attribute_scores

func get_breath_dice() -> Array[Die]:
	return DiceRoller.generate_dice_pool(_breath_dice)
