class_name MonsterProfile
extends ActorProfile

@export var portrait: Texture2D

@export var attribute_scores: Dictionary[CharacterAttribute, int] = {
	Rules.STRENGTH: 7,
	Rules.AGILITY: 7,
	Rules.INTELLIGENCE: 7,
}

## Applied to every weapon, piece of armour and shield when it is handed out, e.g. "battered".
## No weapons = natural weapons: the breath dice also count as weapon dice. Monsters always fight with the first usable one.
@export var equipment_modifiers: Array[EquipmentModifier] = []
## How it fights with its gear; none: never forces a weapon or shield, spares its armour
@export var weapon_tactic: WeaponTactic
@export var shield_tactic: ShieldTactic
@export var armor_tactic: ArmorTactic
## Used while the monster has a usable weapon (natural weapons always are)
@export var attack: MonsterAttack = preload("uid://c4a0yss3o6pxw")  # guts_attack.tres

@export var _breath_dice_size: DieType = Rules.d8
@export var _breath_dice_amount: int = 3

func get_breath_dice() -> Dictionary[DieType, int]:
	return {_breath_dice_size: _breath_dice_amount}

func get_weapon_modifiers() -> Array[EquipmentModifier]: return equipment_modifiers
func get_armor_modifiers() -> Array[EquipmentModifier]: return equipment_modifiers
func get_shield_modifiers() -> Array[EquipmentModifier]: return equipment_modifiers
func get_attribute_score(attribute: CharacterAttribute) -> int: return attribute_scores.get(attribute, 0)

func with_attribute_score(attribute: CharacterAttribute, score: int) -> ActorProfile:
	var copy: MonsterProfile = duplicate()
	copy.attribute_scores = attribute_scores.duplicate()
	copy.attribute_scores[attribute] = score
	return copy

func can_fight() -> bool: return true

func get_actor_scene() -> PackedScene: return load("uid://kmifqq0ejuri")  # monster.tscn
