@tool
class_name ExtraWeaponDiceAbility
extends Ability

## E.g. 1: a d10 sword rolls 2d10
@export_range(1, 3) var count: int = 1

func get_extra_weapon_dice() -> int: return count
