class_name MonsterProfile
extends Resource

@export_placeholder("Name") var name: String
@export var portrait: Texture2D

@export var attribute_scores: Dictionary[CharacterAttribute, int] = {
	Rules.STRENGTH: 7,
	Rules.AGILITY: 7,
	Rules.INTELLIGENCE: 7,
}

@export var _breath_dice_size: DieType = Rules.d8
@export var _breath_dice_amount: int = 3

static func create(
	new_name: String,
	new_portrait: Texture2D,
	new_attribute_scores: Dictionary[CharacterAttribute, RolledAttributeScore],
	new_origins: Array[Origin],
) -> CharacterProfile:
	var character_profile: CharacterProfile = CharacterProfile.new()
	character_profile.name = new_name
	character_profile.portrait = new_portrait
	character_profile.attribute_scores = new_attribute_scores
	character_profile.origins = new_origins
	return character_profile

#func get_attribute_scores() -> Dictionary[CharacterAttribute, AttributeScore]:
	#var attibute_scores: Dictionary[CharacterAttribute, AttributeScore] = {}
	#for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		#var modifiers: Array[AttributeScore.Modifier] = []
		#attibute_scores[attribute] = AttributeScore.create_with_modifiers(attribute, attribute_scores[attribute], modifiers)
	#assert(attibute_scores.size() == Rules.ATTRIBUTES.size())
	#return attibute_scores

func get_breath_dice() -> Array[Die]:
	return DiceRoller.generate_dice_pool({_breath_dice_size: _breath_dice_amount})
