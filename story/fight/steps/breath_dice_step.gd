class_name BreathDiceStep
extends ResolutionStep

func applies(fight: Fight) -> bool: return not get_side(fight).lost_breath_dice.is_empty()

## This side loses its breath dice (origins may spare some, which is told)
func enter(fight: Fight) -> String:
	var rolled_lost: Array[Die] = get_side(fight).lost_breath_dice
	var lost: Array[Die] = get_actor(fight).get_lost_breath_dice(rolled_lost)
	get_actor(fight).lose_breath_dice(lost)
	var lines: Array[String] = []
	if not lost.is_empty(): lines.append("%s %s %d breath %s." % [get_subject(fight), pick(fight, "lose", "loses"), lost.size(), "die" if lost.size() == 1 else "dice"])
	if lost.size() < rolled_lost.size():
		var sparing: Array[String] = get_actor(fight).get_origin_names(func(ability: Ability) -> bool: return ability.modify_lost_breath_dice(rolled_lost).size() < rolled_lost.size())
		lines.append("%s %s %s %d of %d breath dice." % [" and ".join(sparing), "spare" if sparing.size() > 1 else "spares", get_object(fight), rolled_lost.size() - lost.size(), rolled_lost.size()])
	return _join(lines)
