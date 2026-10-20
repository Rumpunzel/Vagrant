class_name ArmorStep
extends ExchangeStep

## The foe's blows against this side's armour: each blocked die marks the foe's weapon and one random blocking piece
func enter(fight: Fight) -> String:
	var lines: Array[String] = []
	for blocked_die: Die in get_foe_side(fight).blocked_weapon_dice:
		var blocking: Array[Armor] = []
		blocking.assign(get_actor(fight).armor.filter(func(piece: Armor) -> bool: return piece.blocks(blocked_die.result)))
		if not blocking.is_empty():
			var piece: Armor = blocking.pick_random()
			lines.append("%s %s blocks the %d." % [get_owner(fight).capitalize(), piece.get_equipment_name(), blocked_die.result])
			lines.append(_mark(piece, blocked_die.result, get_owner(fight)))
		lines.append(_mark(get_foe_weapon(fight), blocked_die.result, get_foe_owner(fight)))
	var prevented: int = get_side(fight).damage_prevented
	if prevented > 0: lines.append(pick("Your armour takes %d off the %s's blow." % [prevented, fight.monster.get_monster_name()], "The %s's armour takes %d off your blow." % [fight.monster.get_monster_name(), prevented]))
	return _join(lines)
