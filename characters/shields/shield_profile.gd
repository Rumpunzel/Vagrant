class_name ShieldProfile
extends Resource

@export_placeholder("Name") var name: String
@export var die: DieType
## Rolling above this attribute's score means the shield cannot be raised in that exchange
@export var wield_attribute: CharacterAttribute = Rules.STRENGTH

static func create(new_name: String, new_die: DieType, new_wield_attribute: CharacterAttribute = Rules.STRENGTH) -> ShieldProfile:
	var shield_profile: ShieldProfile = ShieldProfile.new()
	shield_profile.name = new_name
	shield_profile.die = new_die
	shield_profile.wield_attribute = new_wield_attribute
	return shield_profile
