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
@export var armor: Array[ArmorProfile] = []
## Only the first usable one is raised
@export var shields: Array[ShieldProfile] = []
## Applied to every weapon, piece of armour and shield above when it is handed out, e.g. "battered"
@export var equipment_modifiers: Array[EquipmentModifier] = []
## Used while the monster has a usable weapon (natural weapons always are)
## How it fights with its gear; none: never forces a weapon or shield, spares its armour
@export var weapon_tactic: WeaponTactic
@export var shield_tactic: ShieldTactic
@export var armor_tactic: ArmorTactic
@export var attack: MonsterAttack = preload("uid://c4a0yss3o6pxw")  # guts_attack.tres

@export var _breath_dice_size: DieType = Rules.d8
@export var _breath_dice_amount: int = 3

func get_breath_dice() -> Dictionary[DieType, int]:
	return {_breath_dice_size: _breath_dice_amount}
