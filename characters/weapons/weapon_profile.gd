class_name WeaponProfile
extends ItemProfile

## A weapon as an item: carried, gained and lost like any other, used in fights by its own rules

@export var die: DieType
## Rolling above this attribute's score means the weapon cannot be wielded in that exchange
@export var wield_attribute: CharacterAttribute = Rules.STRENGTH

func is_gear() -> bool: return true

static func create(new_name: String, new_die: DieType, new_wield_attribute: CharacterAttribute = Rules.STRENGTH) -> WeaponProfile:
	var weapon_profile: WeaponProfile = WeaponProfile.new()
	weapon_profile.name = new_name
	weapon_profile.die = new_die
	weapon_profile.wield_attribute = new_wield_attribute
	return weapon_profile
