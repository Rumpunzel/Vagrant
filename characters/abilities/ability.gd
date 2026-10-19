@tool
class_name Ability
extends Resource

## Something an origin grants. A plain ability is only its text; subclasses also change the rules through the hooks below,
## which do nothing by default.

@export_multiline var description: String

func modify_vantage(vantage: int) -> int: return vantage

func get_extra_weapon_dice() -> int: return 0

func modify_lost_breath_dice(lost_breath_dice: Array[Die]) -> Array[Die]: return lost_breath_dice
