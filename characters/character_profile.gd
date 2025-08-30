class_name CharacterProfile
extends Resource

@export_placeholder("Name") var name: String
@export_placeholder("Title") var title: String :
	get: return Origin.concatenate_with_icons(origins) if title.is_empty() else title
@export var portrait: Texture2D = preload("res://assets/portraits/knight.jpeg")

## The character's attribute scores. Will be rolled with 2d6 if null.
@export var base_attribute_scores: Dictionary[CharacterAttribute, BaseAttributeScore] = {
	Rules.STRENGTH: null,
	Rules.AGILITY: null,
	Rules.INTELLIGENCE: null,
}

@export var origins: Array[Origin]

@export var _breath_dice: Dictionary[DieType, int] = {
	Rules.d4: 1,
	Rules.d6: 1,
	Rules.d8: 1,
	Rules.d10: 1,
	Rules.d12: 1,
}

func _init(
	new_name: String,
	new_title: String,
	new_portrait: Texture2D,
	new_base_attribute_scores: Dictionary[CharacterAttribute, BaseAttributeScore],
	new_origins: Array[Origin],
) -> void:
	name = new_name
	title = new_title
	portrait = new_portrait
	base_attribute_scores = new_base_attribute_scores
	origins = new_origins

func get_attribute_scores() -> Dictionary[CharacterAttribute, AttributeScore]:
	var attibute_scores: Dictionary[CharacterAttribute, AttributeScore] = {}
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var modifiers: Array[AttributeScore.Modifier] = []
		for origin: Origin in origins:
			modifiers.append_array(origin.get_attribute_score_modifiers())
		attibute_scores[attribute] = AttributeScore.create_with_modifiers(attribute, base_attribute_scores[attribute], modifiers)
	assert(attibute_scores.size() == Rules.ATTRIBUTES.size())
	return attibute_scores

func get_breath_dice() -> Array[Die]:
	return DiceRoller.generate_dice_pool(_breath_dice)
