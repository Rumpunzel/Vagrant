class_name BreathDiceStep
extends ExchangeStep

func applies(fight: Fight) -> bool: return not get_side(fight).lost_breath_dice.is_empty()

## This side's breath dice are lost and its weapon gets marked where it could not be wielded
func enter(fight: Fight) -> String:
	var fight_side: FightSide = get_side(fight)
	var lost: Array[Die] = fight_side.lost_breath_dice
	get_actor(fight).lose_breath_dice(lost)
	var lines: Array[String] = []
	if not lost.is_empty(): lines.append("%s %s %d breath %s." % [get_subject(fight), pick("lose", "loses"), lost.size(), "die" if lost.size() == 1 else "dice"])
	return _join(lines)
