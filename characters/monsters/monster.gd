class_name Monster
extends Node

signal lost_breath(lost_breath_dice: Array[Die])
signal suffered_injury(injury: Injury)

@export var monster_profile: MonsterProfile :
	set(new_monster_profile):
		assert(new_monster_profile)
		monster_profile = new_monster_profile
		recover_breath()

var breath_dice: Dictionary[DieType, int]

var _injuries: Array[Injury] = []

func lose_breath_dice(lost_breath_dice: Array[Die]) -> void:
	if lost_breath_dice.is_empty(): return
	for breath_die: Die in lost_breath_dice:
		breath_dice[breath_die.die_type] = breath_dice[breath_die.die_type] - 1
		assert(breath_dice[breath_die.die_type] >= 0)
	lost_breath.emit(lost_breath_dice)

## For now monsters fully recover their breath between fights
func recover_breath() -> void:
	breath_dice = monster_profile.get_breath_dice()

func suffer_injury(injury: Injury) -> void:
	assert(injury.magnitude > 0)
	_injuries.append(injury)
	suffered_injury.emit(injury)

func is_out_of_breath() -> bool:
	for amount: int in breath_dice.values(): if amount > 0: return false
	return true

func get_monster_name() -> String: return monster_profile.name
func get_nature() -> CharacterAttribute: return monster_profile.nature

## Injuries reduce all attributes by their total magnitude
func get_score(attribute: CharacterAttribute) -> int:
	var score: int = monster_profile.attribute_scores[attribute]
	for injury: Injury in _injuries: score -= injury.magnitude
	return score

## Fixed rule: monsters always roll all of their breath dice
func get_breath_dice_pool() -> Array[Die]:
	return DiceRoller.generate_dice_pool(breath_dice)

func get_weapon_dice() -> Array[WeaponDie]:
	var weapon_dice: Array[WeaponDie] = []
	for die_type: DieType in monster_profile.weapon_dice: weapon_dice.append(WeaponDie.new(die_type))
	return weapon_dice
