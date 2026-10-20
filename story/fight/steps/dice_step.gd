class_name DiceStep
extends ExchangeStep

## "You threaten with Guts (4) and your Sword (3)." / "The Lurker threatens with Nerves (6) and its Knife (7)."
func enter(fight: Fight) -> String:
	var dice_side: FightSide = get_side(fight)
	var text: String = "%s with %s (%d)" % [_get_verb(dice_side), Fight.describe_attribute(dice_side.stance), dice_side.threat]
	var weapon: Weapon = get_weapon(fight)
	if weapon and not dice_side.weapon_dice.is_empty():
		var results: Array[String] = []
		for die: Die in dice_side.weapon_dice: results.append(str(die.result))
		text += " and %s %s (%s)" % [pick("your", "its"), weapon.get_equipment_name(), ", ".join(results)]
	return "%s %s." % [get_subject(fight), text]

func _get_verb(dice_side: FightSide) -> String:
	if dice_side.fleeing: return pick("flee", "flees")
	return pick("threaten", "threatens")
