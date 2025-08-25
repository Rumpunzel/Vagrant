class_name CharacterProfile
extends Resource

@export_placeholder("Name") var name: String
@export var portrait: Texture = preload("res://assets/portraits/knight.jpeg")

@export_group("Attributes")
## The character's strength score. Will be rolled with 2d6 if null.
@export var _strength: AttributeScore
## The character's agility score. Will be rolled with 2d6 if null.
@export var _agility: AttributeScore
## The character's intelligence score. Will be rolled with 2d6 if null.
@export var _intelligence: AttributeScore

@export_group("Hit Dice")
@export var _d4_hit_dice: int = 1
@export var _d6_hit_dice: int = 1
@export var _d8_hit_dice: int = 1
@export var _d10_hit_dice: int = 1
@export var _d12_hit_dice: int = 1

func get_attribute_scores() -> Dictionary[CharacterAttribute, AttributeScore]:
	return {
		Rules.STRENGTH: _strength,
		Rules.AGILITY: _agility,
		Rules.INTELLIGENCE: _intelligence,
	}

func get_hit_dice() -> Array[Die]:
	return DiceRoller.generate_dice_pool(_d4_hit_dice, _d6_hit_dice, _d8_hit_dice, _d10_hit_dice, _d12_hit_dice)

# WARNING: This may return a randomly rolled attribute
func get_attribute_score(attribute: CharacterAttribute) -> AttributeScore:
	return get_attribute_scores()[attribute]
