class_name WeaponCheckStep
extends ExchangeStep

## This side's breath dice are lost and its weapon gets marked where it could not be wielded
func enter(fight: Fight) -> String:
	var dice_side: FightSide = get_side(fight)
	var lines: Array[String] = []
	if not dice_side.failed_weapon_dice.is_empty(): lines.append("%s %s to wield %s weapon." % [get_subject(fight), pick("fail", "fails"), pick("your", "its")])
	for failed_die: Die in dice_side.failed_weapon_dice: lines.append(_mark(get_weapon(fight), failed_die.result, get_owner(fight)))
	return _join(lines)
