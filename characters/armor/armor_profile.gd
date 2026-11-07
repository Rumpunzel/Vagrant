class_name ArmorProfile
extends ItemProfile

## A armour as an item: carried, gained and lost like any other, used in fights by its own rules

## Weapon die results this piece blocks; a blocked die deals no damage
@export var blocked_results: Array[int] = []
## Subtracted from all damage taken, after everything else
@export_range(0, 12) var damage_reduction: int = 0

func is_gear() -> bool: return true

static func create(new_name: String, new_blocked_results: Array[int] = [], new_damage_reduction: int = 0) -> ArmorProfile:
	var armor_profile: ArmorProfile = ArmorProfile.new()
	armor_profile.name = new_name
	armor_profile.blocked_results = new_blocked_results
	armor_profile.damage_reduction = new_damage_reduction
	return armor_profile
