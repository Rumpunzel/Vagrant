class_name BreathDiceStep
extends ExchangeStep

func applies(fight: Fight) -> bool: return not get_side(fight).lost_breath_dice.is_empty()

## This side loses its breath dice (origins may spare some)
func enter(fight: Fight) -> String:
	var lost: Array[Die] = get_actor(fight).get_lost_breath_dice(get_side(fight).lost_breath_dice)
	get_actor(fight).lose_breath_dice(lost)
	var lines: Array[String] = []
	if not lost.is_empty(): lines.append("%s %s %d breath %s." % [get_subject(fight), pick(fight, "lose", "loses"), lost.size(), "die" if lost.size() == 1 else "dice"])
	return _join(lines)
