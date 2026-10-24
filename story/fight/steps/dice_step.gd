class_name DiceStep
extends ExchangeStep

## "You threaten with Guts (6) and your Sword (9)." / "The Lurker threatens with Nerves (4), forcing its Knife (7, −2): a threat of 2."
func enter(fight: Fight) -> String:
	var dice_side: FightSide = get_side(fight)
	var parts: Array[String] = ["%s (%d)" % [Fight.describe_attribute(dice_side.stance), FightExchange.get_highest_result(dice_side.breath_dice)]]
	var forced: Array[String] = []
	var weapon: Weapon = get_weapon(fight)
	if weapon and not dice_side.usable_weapon_dice.is_empty():
		var weapon_text: String = "%s %s (%d" % [get_pronoun(fight), weapon.get_equipment_name(), dice_side.usable_weapon_dice[0].result]
		if dice_side.weapon_overshoot > 0: forced.append("%s, −%d)" % [weapon_text, dice_side.weapon_overshoot])
		elif dice_side.weapon_strain == FightSide.Strain.NONE: parts.append(weapon_text + ")")
	var shield: Shield = get_shield(fight)
	if shield and dice_side.raises_shield:
		var shield_text: String = "%s %s (%d" % [get_pronoun(fight), shield.get_equipment_name(), dice_side.shield_dice[0].result]
		if dice_side.shield_overshoot > 0: forced.append("%s, −%d)" % [shield_text, dice_side.shield_overshoot])
		else: parts.append(shield_text + ")")
	var text: String = "%s with %s" % [_get_verb(fight, dice_side), _list(parts)]
	if not forced.is_empty(): text += ", forcing %s: a threat of %d" % [_list(forced), dice_side.threat]
	return "%s %s." % [get_subject(fight), text]

static func _list(items: Array[String]) -> String:
	if items.size() == 1: return items[0]
	return "%s and %s" % [", ".join(items.slice(0, -1)), items[-1]]

func _get_verb(fight: Fight, dice_side: FightSide) -> String:
	if dice_side.fleeing: return pick(fight, "flee", "flees")
	return pick(fight, "threaten", "threatens")
