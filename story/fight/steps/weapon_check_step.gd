class_name WeaponCheckStep
extends ExchangeStep

## Marks what forcing the weapon cost, and tells when this side held back
func enter(fight: Fight) -> String:
	var dice_side: FightSide = get_side(fight)
	var weapon: Weapon = get_weapon(fight)
	if dice_side.usable_weapon_dice.is_empty():
		if dice_side.failed_weapon_dice.is_empty() or not weapon: return ""
		return "%s %s back %s %s." % [get_subject(fight), pick("hold", "holds"), pick("your", "its"), weapon.get_equipment_name()]
	var die: Die = dice_side.usable_weapon_dice[0]
	match dice_side.weapon_strain:
		FightSide.Strain.OVERREACH:
			weapon.mark_all()
			return "%s %s %s %s beyond %s strength: every face is marked." % [get_subject(fight), pick("force", "forces"), pick("your", "its"), weapon.get_equipment_name(), pick("your", "its")]
		FightSide.Strain.MARKED_FACE:
			return "%s %s the marked %d. %s" % [get_subject(fight), pick("force", "forces"), die.result, _mark(weapon, die.result, get_owner(fight))]
	return ""
