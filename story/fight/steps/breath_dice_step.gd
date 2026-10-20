class_name BreathDiceStep
extends ExchangeStep

## This side's breath dice are lost and its weapon gets marked where it could not be wielded
func enter(fight: Fight) -> String:
	var dice_side: FightSide = get_side(fight)
	var lost: Array[Die] = fight.player_lost_breath_dice if is_player() else dice_side.lost_breath_dice
	if is_player(): fight.protagonist.lose_breath_dice(lost)
	else: fight.monster.lose_breath_dice(lost)
	var lines: Array[String] = []
	if not lost.is_empty(): lines.append("%s %s %d breath %s." % [get_subject(fight), pick("lose", "loses"), lost.size(), "die" if lost.size() == 1 else "dice"])
	return _join(lines)
