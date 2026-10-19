class_name Monster
extends Node

signal lost_breath(lost_breath_dice: Array[Die])
signal suffered_injury(injury: Injury)

const UNARMED_ATTACK: MonsterAttack = preload("uid://c4a0yss3o6pxw")  # guts_attack.tres

@export var monster_profile: MonsterProfile :
	set(new_monster_profile):
		assert(new_monster_profile)
		monster_profile = new_monster_profile
		weapons = Weapon.carry(monster_profile.weapons, monster_profile.equipment_modifiers)
		armor = Armor.carry(monster_profile.armor, monster_profile.equipment_modifiers)
		shields = Shield.carry(monster_profile.shields, monster_profile.equipment_modifiers)
		recover_breath()

@export var spawned_from: AdventurePage

var breath_dice: Dictionary[DieType, int]
var weapons: Array[Weapon] = []
var armor: Array[Armor] = []
var shields: Array[Shield] = []

var _injuries: Array[Injury] = []

func lose_breath_dice(lost_breath_dice: Array[Die]) -> void:
	if lost_breath_dice.is_empty(): return
	for breath_die: Die in lost_breath_dice:
		breath_dice[breath_die.die_type] = breath_dice[breath_die.die_type] - 1
		assert(breath_dice[breath_die.die_type] >= 0)
	lost_breath.emit(lost_breath_dice)

func recover_breath() -> void:
	breath_dice = monster_profile.get_breath_dice()

func suffer_injury(injury: Injury) -> void:
	assert(injury.magnitude > 0)
	_injuries.append(injury)
	suffered_injury.emit(injury)

func get_injury_total() -> int:
	var total: int = 0
	for injury: Injury in _injuries: total += injury.magnitude
	return total

## Injuries brought at least one score to 0 or below: every further injury calls for a Guts save against all injuries
func is_overwhelmed_by_injuries() -> bool:
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: if get_score(attribute) <= 0: return true
	return false

func get_breath_dice_count() -> int:
	var count: int = 0
	for amount: int in breath_dice.values(): count += amount
	return count

func is_out_of_breath() -> bool:
	for amount: int in breath_dice.values(): if amount > 0: return false
	return true

func get_monster_name() -> String: return monster_profile.name
## Unarmed, a monster threatens with Guts like anyone else
func get_attack() -> MonsterAttack: return monster_profile.attack if has_natural_weapons() or get_weapon() else UNARMED_ATTACK

func get_score(attribute: CharacterAttribute) -> int:
	var score: int = monster_profile.attribute_scores[attribute]
	for injury: Injury in _injuries: score -= injury.magnitude
	return score

func get_breath_dice_pool() -> Array[Die]:
	return DiceRoller.generate_dice_pool(breath_dice)

func has_natural_weapons() -> bool: return monster_profile.weapons.is_empty()

func get_weapon() -> Weapon: return Weapon.get_first_usable(weapons)
