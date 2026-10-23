class_name WeaponCheckStep
extends ExchangeStep

## Marks what forcing the weapon cost, and tells when this side held back
func enter(fight: Fight) -> String:
	var dice_side: FightSide = get_side(fight)
	var weapon: Weapon = get_weapon(fight)
	if not weapon or dice_side.has_natural_weapons or dice_side.weapon_dropped: return ""
	if dice_side.usable_weapon_dice.is_empty():
		return "%s %s back %s %s." % [get_subject(fight), pick("hold", "holds"), pick("your", "its"), weapon.get_equipment_name()]
	var die: Die = dice_side.usable_weapon_dice[0]
	match dice_side.weapon_strain:
		FightSide.Strain.OVERREACH:
			return "%s %s %s %s: %s." % [get_subject(fight), pick("force", "forces"), pick("your", "its"), weapon.get_equipment_name(), _mark_times(weapon, die.result, dice_side.weapon_overshoot)]
		FightSide.Strain.MARKED_FACE:
			return "%s %s the marked %d. %s" % [get_subject(fight), pick("force", "forces"), die.result, _mark(weapon, die.result, get_owner(fight))]
	return ""

## Marks [param face] and then the next higher faces, [param times] in all or until the weapon is ruined: "the 9 and 10 are marked"
static func _mark_times(weapon: Weapon, face: int, times: int) -> String:
	var marked: Array[String] = []
	for _index: int in times:
		if not weapon.is_usable(): break
		var marked_face: int = weapon.mark(face)
		if marked_face > 0: marked.append(str(marked_face))
	var text: String = "the %s %s marked" % [" and ".join(marked), "is" if marked.size() == 1 else "are"] if not marked.is_empty() else ""
	if weapon.ruined: text = "%s, then it is ruined" % text if not text.is_empty() else "it is ruined"
	return text
