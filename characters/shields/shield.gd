class_name Shield
extends Equipment

@export var shield_profile: ShieldProfile

static func create(new_shield_profile: ShieldProfile, new_marked_faces: Array[int] = [], new_ruined: bool = false) -> Shield:
	assert(new_shield_profile and new_shield_profile.die)
	var shield: Shield = Shield.new()
	shield.shield_profile = new_shield_profile
	shield._set_state(new_marked_faces, new_ruined)
	return shield

func get_markable_faces() -> Array[int]:
	var faces: Array[int] = []
	faces.assign(range(1, shield_profile.die.faces + 1))
	return faces

func get_equipment_name() -> String: return shield_profile.name
func get_die_type() -> DieType: return shield_profile.die
func get_wield_attribute() -> CharacterAttribute: return shield_profile.wield_attribute

static func get_first_usable(shields: Array[Shield]) -> Shield:
	for shield: Shield in shields: if shield.is_usable(): return shield
	return null

static func carry(shield_profiles: Array[ShieldProfile], modifiers: Array[EquipmentModifier] = []) -> Array[Shield]:
	var shields: Array[Shield] = []
	for shield_profile_to_carry: ShieldProfile in shield_profiles:
		var shield: Shield = Shield.create(shield_profile_to_carry)
		for modifier: EquipmentModifier in modifiers: modifier.modify(shield)
		shields.append(shield)
	return shields
