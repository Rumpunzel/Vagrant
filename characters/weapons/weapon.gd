class_name Weapon
extends Equipment

@export var weapon_profile: WeaponProfile

static func create(new_weapon_profile: WeaponProfile, new_marked_faces: Array[int] = [], new_ruined: bool = false) -> Weapon:
	assert(new_weapon_profile and new_weapon_profile.die)
	var weapon: Weapon = Weapon.new()
	weapon.weapon_profile = new_weapon_profile
	weapon._set_state(new_marked_faces, new_ruined)
	return weapon

func get_markable_faces() -> Array[int]:
	var faces: Array[int] = []
	faces.assign(range(1, weapon_profile.die.faces + 1))
	return faces

func get_equipment_name() -> String: return weapon_profile.name
func get_die_type() -> DieType: return weapon_profile.die
func get_wield_attribute() -> CharacterAttribute: return weapon_profile.wield_attribute

static func get_first_usable(weapons: Array[Weapon]) -> Weapon:
	for weapon: Weapon in weapons: if weapon.is_usable(): return weapon
	return null

static func carry(weapon_profiles: Array[WeaponProfile], modifiers: Array[EquipmentModifier] = []) -> Array[Weapon]:
	var weapons: Array[Weapon] = []
	for weapon_profile_to_carry: WeaponProfile in weapon_profiles:
		var weapon: Weapon = Weapon.create(weapon_profile_to_carry)
		for modifier: EquipmentModifier in modifiers: modifier.modify(weapon)
		weapons.append(weapon)
	return weapons
