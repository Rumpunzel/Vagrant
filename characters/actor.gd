@abstract
class_name Actor
extends Node

## What characters and monsters share: breath dice, injuries and gear.

signal lost_breath(lost_breath_dice: Array[Die])
signal suffered_injury(injury: Injury)
signal injuries_changed(injuries: Array[Injury])
signal breath_dice_changed(breath_dice: Dictionary[Die, int])

var breath_dice: Dictionary[DieType, int] :
	set(new_breath_dice):
		if new_breath_dice == breath_dice: return
		breath_dice = new_breath_dice
		breath_dice_changed.emit(breath_dice)

var weapons: Array[Weapon] = []
var armor: Array[Armor] = []
var shields: Array[Shield] = []

# TODO: if you roll under an injury, increase magnitude by 1
var _injuries: Array[Injury] :
	set(new_injuries):
		if new_injuries == _injuries: return
		_injuries = new_injuries
		injuries_changed.emit(_injuries)

## The effective score: injuries already taken off
@abstract func get_score(attribute: CharacterAttribute) -> int

func lose_breath_dice(lost_breath_dice: Array[Die]) -> void:
	if lost_breath_dice.is_empty(): return
	var new_breath_dice: Dictionary[DieType, int] = breath_dice.duplicate()
	for breath_die: Die in lost_breath_dice:
		new_breath_dice[breath_die.die_type] = new_breath_dice[breath_die.die_type] - 1
		assert(new_breath_dice[breath_die.die_type] >= 0)
	breath_dice = new_breath_dice
	lost_breath.emit(lost_breath_dice)

# TODO: injuries from outside fights (consequences) should also call for the incapacitation save; what being incapacitated means there is open
func suffer_injury(injury: Injury) -> void:
	assert(injury.magnitude > 0)
	_injuries.append(injury)
	injuries_changed.emit(_injuries)
	suffered_injury.emit(injury)

func get_injury_total() -> int:
	var total: int = 0
	for injury: Injury in _injuries: total += injury.magnitude
	return total

## Injuries brought at least one score to 0 or below: every further injury calls for a Guts save against all injuries
func is_overwhelmed_by_injuries() -> bool:
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: if get_score(attribute) <= 0: return true
	return false

## Picks up what the foe's Nerves made this actor drop
func pick_up_dropped_gear() -> void:
	for weapon: Weapon in weapons: weapon.dropped = false
	for shield: Shield in shields: shield.dropped = false

func get_breath_dice_count() -> int:
	var count: int = 0
	for amount: int in breath_dice.values(): count += amount
	return count

func is_out_of_breath() -> bool: return get_breath_dice_count() == 0

func get_breath_dice_pool() -> Array[Die]:
	return DiceRoller.generate_dice_pool(breath_dice)
