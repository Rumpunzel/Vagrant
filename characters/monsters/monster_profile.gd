class_name MonsterProfile
extends Resource

@export_placeholder("Name") var name: String
@export var portrait: Texture2D

@export var attribute_scores: Dictionary[CharacterAttribute, int] = {
	Rules.STRENGTH: 7,
	Rules.AGILITY: 7,
	Rules.INTELLIGENCE: 7,
}

## [] = natural weapons: the breath dice also count as weapon dice. Monsters always fight with the first usable one
@export var weapons: Array[WeaponProfile] = []
## Applied to every weapon above when it is handed out, e.g. "battered"
@export var weapon_modifiers: Array[EquipmentModifier] = []
@export var armor: Array[ArmorProfile] = []
## Applied to every piece of armour above when it is handed out
@export var armor_modifiers: Array[EquipmentModifier] = []
## Only the first usable one is raised
@export var shields: Array[ShieldProfile] = []
## Applied to every shield above when it is handed out
@export var shield_modifiers: Array[EquipmentModifier] = []
## Nerves is not supported for monsters yet
@export var nature: CharacterAttribute = Rules.STRENGTH

@export var _breath_dice_size: DieType = Rules.d8
@export var _breath_dice_amount: int = 3

func get_breath_dice() -> Dictionary[DieType, int]:
	return {_breath_dice_size: _breath_dice_amount}
