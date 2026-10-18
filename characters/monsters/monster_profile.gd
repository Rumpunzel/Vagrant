class_name MonsterProfile
extends Resource

@export_placeholder("Name") var name: String
@export var portrait: Texture2D

@export var attribute_scores: Dictionary[CharacterAttribute, int] = {
	Rules.STRENGTH: 7,
	Rules.AGILITY: 7,
	Rules.INTELLIGENCE: 7,
}

## [] = unarmed
@export var weapon_dice: Array[DieType] = []
## Nerves is not supported for monsters yet
@export var nature: CharacterAttribute = Rules.STRENGTH

@export var _breath_dice_size: DieType = Rules.d8
@export var _breath_dice_amount: int = 3

func get_breath_dice() -> Dictionary[DieType, int]:
	return {_breath_dice_size: _breath_dice_amount}
