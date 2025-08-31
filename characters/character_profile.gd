class_name CharacterProfile
extends Resource

@export_placeholder("Name") var name: String
@export var portrait: Texture2D = preload("res://assets/portraits/knight.jpeg")

## The character's attribute scores. Will be rolled with 2d6 if null.
@export var base_attribute_scores: Dictionary[CharacterAttribute, BaseAttributeScore] = {
	Rules.STRENGTH: null,
	Rules.AGILITY: null,
	Rules.INTELLIGENCE: null,
}

@export var origins: Array[Origin]

@export_placeholder("Title") var _title: String
@export var _breath_dice: Dictionary[DieType, int] = {
	Rules.d4: 1,
	Rules.d6: 1,
	Rules.d8: 1,
	Rules.d10: 1,
	Rules.d12: 1,
}

static func create(
	new_name: String,
	new_portrait: Texture2D,
	new_base_attribute_scores: Dictionary[CharacterAttribute, BaseAttributeScore],
	new_origins: Array[Origin],
	new_title: String,
) -> CharacterProfile:
	var character_profile: CharacterProfile = CharacterProfile.new()
	character_profile.name = new_name
	character_profile.portrait = new_portrait
	character_profile.base_attribute_scores = new_base_attribute_scores
	character_profile.origins = new_origins
	character_profile._title = new_title
	return character_profile

func get_attribute_scores() -> Dictionary[CharacterAttribute, AttributeScore]:
	var attibute_scores: Dictionary[CharacterAttribute, AttributeScore] = {}
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var modifiers: Array[AttributeScore.Modifier] = []
		for origin: Origin in origins:
			modifiers.append_array(origin.get_attribute_score_modifiers())
		attibute_scores[attribute] = AttributeScore.create_with_modifiers(attribute, base_attribute_scores[attribute], modifiers)
	assert(attibute_scores.size() == Rules.ATTRIBUTES.size())
	return attibute_scores

func get_breath_dice() -> Array[BreathDie]:
	return DiceRoller.generate_breath_dice_pool(_breath_dice)

func get_title() -> String:
	return Origin.concatenate_with_icons(origins) if _title.is_empty() else _title
