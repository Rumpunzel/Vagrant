class_name Weapon
extends Resource

## A weapon as carried by a character or monster, with the faces it has had marked.
## Failing to wield it marks the face that came up; failing on an already marked face ruins it.
## A marked face deals no damage. Ruined weapons stay visible but can no longer be used.
## A resource, so a weapon can also be authored in a given state (e.g. already marked).

enum Mark {
	MARKED,
	RUINED,
}

@export var weapon_profile: WeaponProfile
@export var marked_faces: Array[int] = []
@export var ruined: bool = false

static func create(new_weapon_profile: WeaponProfile, new_marked_faces: Array[int] = [], new_ruined: bool = false) -> Weapon:
	assert(new_weapon_profile and new_weapon_profile.die)
	var weapon: Weapon = Weapon.new()
	weapon.weapon_profile = new_weapon_profile
	weapon.marked_faces = new_marked_faces.duplicate()
	weapon.marked_faces.sort()
	weapon.ruined = new_ruined
	return weapon

func mark(face: int) -> Mark:
	assert(not ruined)
	assert(face >= 1 and face <= weapon_profile.die.faces)
	if marked_faces.has(face):
		ruined = true
		return Mark.RUINED
	marked_faces.append(face)
	marked_faces.sort()
	return Mark.MARKED

func is_usable() -> bool: return not ruined
func is_marked(face: int) -> bool: return marked_faces.has(face)
func get_weapon_name() -> String: return weapon_profile.name
func get_die_type() -> DieType: return weapon_profile.die
func get_wield_attribute() -> CharacterAttribute: return weapon_profile.wield_attribute

## First usable weapon, or null
static func get_first_usable(weapons: Array[Weapon]) -> Weapon:
	for weapon: Weapon in weapons: if weapon.is_usable(): return weapon
	return null

## Fresh weapons for a character or monster carrying [param weapon_profiles], each shaped by [param modifiers]
static func carry(weapon_profiles: Array[WeaponProfile], modifiers: Array[WeaponModifier] = []) -> Array[Weapon]:
	var weapons: Array[Weapon] = []
	for weapon_profile_to_carry: WeaponProfile in weapon_profiles:
		var weapon: Weapon = Weapon.create(weapon_profile_to_carry)
		for modifier: WeaponModifier in modifiers: modifier.modify(weapon)
		weapons.append(weapon)
	return weapons
