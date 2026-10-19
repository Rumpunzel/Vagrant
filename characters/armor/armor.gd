class_name Armor
extends Equipment

## Marked results still block.

@export var armor_profile: ArmorProfile

static func create(new_armor_profile: ArmorProfile, new_marked_faces: Array[int] = [], new_ruined: bool = false) -> Armor:
	assert(new_armor_profile)
	var armor: Armor = Armor.new()
	armor.armor_profile = new_armor_profile
	armor._set_state(new_marked_faces, new_ruined)
	return armor

func get_markable_faces() -> Array[int]: return armor_profile.blocked_results
func get_equipment_name() -> String: return armor_profile.name

func blocks(result: int) -> bool: return is_usable() and armor_profile.blocked_results.has(result)
func get_damage_reduction() -> int: return armor_profile.damage_reduction if is_usable() else 0

## Every result blocked by at least one usable piece
static func get_blocked_results(armor: Array[Armor]) -> Array[int]:
	var blocked: Array[int] = []
	for piece: Armor in armor:
		for result: int in piece.armor_profile.blocked_results: if piece.blocks(result) and not blocked.has(result): blocked.append(result)
	return blocked

static func get_total_damage_reduction(armor: Array[Armor]) -> int:
	var total: int = 0
	for piece: Armor in armor: total += piece.get_damage_reduction()
	return total

static func carry(armor_profiles: Array[ArmorProfile], modifiers: Array[EquipmentModifier] = []) -> Array[Armor]:
	var armor: Array[Armor] = []
	for armor_profile_to_wear: ArmorProfile in armor_profiles:
		var piece: Armor = Armor.create(armor_profile_to_wear)
		for modifier: EquipmentModifier in modifiers: modifier.modify(piece)
		armor.append(piece)
	return armor
