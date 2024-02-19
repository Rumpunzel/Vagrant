class_name CharacterProfile
extends Resource

@export_placeholder("Name") var name: String
@export var portrait: Texture = preload("res://portraits/knight.jpeg")

@export_group("Attributes")
## The character's strength score. Will be rolled with 2d6 if equal to or less than 0.
@export_range(0, 12) var _strength := 0
## The character's agility score. Will be rolled with 2d6 if equal to or less than 0.
@export_range(0, 12) var _agility := 0
## The character's constitution score. Will be rolled with 2d6 if equal to or less than 0.
@export_range(0, 12) var _constitution := 0
## The character's intelligence score. Will be rolled with 2d6 if equal to or less than 0.
@export_range(0, 12) var _intelligence := 0
## The character's will score. Will be rolled with 2d6 if equal to or less than 0.
@export_range(0, 12) var _will := 0
## The character's charisma score. Will be rolled with 2d6 if equal to or less than 0.
@export_range(0, 12) var _charisma := 0

@export_group("Hit Dice")
@export var _d4_hit_dice := 1
@export var _d6_hit_dice := 1
@export var _d8_hit_dice := 1
@export var _d10_hit_dice := 1
@export var _d12_hit_dice := 1

# CharacterAttribute -> int
func get_attribute_scores() -> Dictionary:
	var strength := _strength if _strength > 0 else roll_attribute()
	var agility := _agility if _agility > 0 else roll_attribute()
	var constitution := _constitution if _constitution > 0 else roll_attribute()
	var intelligence := _intelligence if _intelligence > 0 else roll_attribute()
	var will := _will if _will > 0 else roll_attribute()
	var charisma := _charisma if _charisma > 0 else roll_attribute()
	return {
		Rules.STRENGTH: strength,
		Rules.AGILITY: agility,
		Rules.CONSTITUTION: constitution,
		Rules.INTELLIGENCE: intelligence,
		Rules.WILL: will,
		Rules.CHARISMA: charisma,
	}

func roll_attribute() -> int:
	return DiceRoller.roll_sum(Rules.d6.get_dice_pool(2))

func get_hit_dice() -> Array[Die]:
	return DiceRoller.generate_dice_pool(_d4_hit_dice, _d6_hit_dice, _d8_hit_dice, _d10_hit_dice, _d12_hit_dice)

# WARNING: This may return a randomly rolled attribute
func get_attribute_score(attribute: CharacterAttribute) -> int:
	return get_attribute_scores()[attribute]
