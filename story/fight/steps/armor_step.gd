class_name ArmorStep
extends ExchangeStep

## The foe's blows against this side's armour: each blocked die marks the foe's weapon and the piece that took it
## (the player's pick from [member Fight.armor_picks], otherwise the side's [ArmorTactic])
func enter(fight: Fight) -> String:
	var lines: Array[String] = []
	for blocked_die: Die in get_foe_side(fight).blocked_weapon_dice:
		var options: Array[ArmorPick] = ArmorPick.get_options(get_actor(fight).armor, blocked_die.result)
		if not options.is_empty():
			var tactic: ArmorTactic = get_side(fight).armor_tactic if get_side(fight).armor_tactic else SparingArmorTactic.new()
			var armor_pick: ArmorPick = fight.armor_picks.get(blocked_die, tactic.pick(options)) as ArmorPick
			var piece_name: String = "%s %s" % [get_owner(fight).capitalize(), armor_pick.piece.get_equipment_name()]
			if armor_pick.ruin:
				armor_pick.piece.ruin()
				lines.append("%s blocks the %d and is ruined." % [piece_name, blocked_die.result])
			else:
				lines.append("%s blocks the %d." % [piece_name, blocked_die.result])
				lines.append(_mark(armor_pick.piece, blocked_die.result, get_owner(fight)))
		lines.append(_mark(get_foe_weapon(fight), blocked_die.result, get_foe_owner(fight)))
	var prevented: int = get_side(fight).damage_prevented
	if prevented > 0: lines.append(pick("Your armour takes %d off the %s's blow." % [prevented, fight.monster.get_monster_name()], "The %s's armour takes %d off your blow." % [fight.monster.get_monster_name(), prevented]))
	return _join(lines)
