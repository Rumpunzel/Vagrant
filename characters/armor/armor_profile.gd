class_name ArmorProfile
extends Resource

@export_placeholder("Name") var name: String
## Weapon die results this piece blocks; a blocked die deals no damage
@export var blocked_results: Array[int] = []
## Subtracted from all damage taken, after everything else
@export_range(0, 12) var damage_reduction: int = 0

static func create(new_name: String, new_blocked_results: Array[int] = [], new_damage_reduction: int = 0) -> ArmorProfile:
	var armor_profile: ArmorProfile = ArmorProfile.new()
	armor_profile.name = new_name
	armor_profile.blocked_results = new_blocked_results
	armor_profile.damage_reduction = new_damage_reduction
	return armor_profile
