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
	var strength: AttributeScore = _strength if _strength else roll_attribute()
	var agility: AttributeScore = _agility if _agility else roll_attribute()
	var intelligence: AttributeScore = _intelligence if _intelligence else roll_attribute()
	return {
		Rules.STRENGTH: strength,
		Rules.AGILITY: agility,
		Rules.INTELLIGENCE: intelligence,
	}

func roll_attribute() -> AttributeScore:
	var rolled_dice: Array[Die] = DiceRoller.roll_dice(Rules.d6.get_dice_pool(2))
	return AttributeScore.new(rolled_dice)

func get_hit_dice() -> Array[Die]:
	return DiceRoller.generate_dice_pool(_d4_hit_dice, _d6_hit_dice, _d8_hit_dice, _d10_hit_dice, _d12_hit_dice)

# WARNING: This may return a randomly rolled attribute
func get_attribute_score(attribute: CharacterAttribute) -> AttributeScore:
	return get_attribute_scores()[attribute]
