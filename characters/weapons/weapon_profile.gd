class_name WeaponProfile
extends Resource

@export_placeholder("Name") var name: String
@export var die: DieType
## Rolling above this attribute's score means the weapon cannot be wielded in that exchange
@export var wield_attribute: CharacterAttribute = Rules.STRENGTH

static func create(new_name: String, new_die: DieType, new_wield_attribute: CharacterAttribute = Rules.STRENGTH) -> WeaponProfile:
	var weapon_profile: WeaponProfile = WeaponProfile.new()
	weapon_profile.name = new_name
	weapon_profile.die = new_die
	weapon_profile.wield_attribute = new_wield_attribute
	return weapon_profile
