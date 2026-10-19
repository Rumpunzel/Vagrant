@tool
class_name Ability
extends Resource

## Something an origin grants. A plain ability is only its text; subclasses also change the rules through the hooks below,
## which do nothing by default.

@export_multiline var description: String

## Fights: the vantage (how much the threat was won by) this side's stance works with
func modify_vantage(vantage: int) -> int: return vantage

## Fights: dice rolled for the wielded weapon on top of its own
func get_extra_weapon_dice() -> int: return 0

## Breath dice lost after a roll
func modify_lost_breath_dice(lost_breath_dice: Array[Die]) -> Array[Die]: return lost_breath_dice
