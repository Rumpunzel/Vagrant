class_name OutcomeStep
extends ExchangeStep

## Ends the exchange for both sides; [member side] has no meaning here
func enter(fight: Fight) -> String:
	fight.outcome = _evaluate(fight)
	var monster_name: String = fight.monster.get_monster_name()
	match fight.outcome:
		Fight.Outcome.WON: return "The %s can no longer resist." % monster_name
		Fight.Outcome.LOST: return "You sink to the ground and can no longer resist." if fight.player_incapacitated else "You are out of breath and can no longer resist."
		Fight.Outcome.DRAW: return "Neither of you can go on."
		Fight.Outcome.FLED: return "You get away from the %s." % monster_name
	return ""

func _evaluate(fight: Fight) -> Fight.Outcome:
	var player_fled: bool = fight.get_last_exchange().first.fleeing
	# Collapsing while running away still lets the foe have you
	if player_fled and fight.player_incapacitated: return Fight.Outcome.LOST
	# Checked before breath: running out of breath only matters for facing the next exchange
	if player_fled: return Fight.Outcome.FLED
	var player_out: bool = fight.player_incapacitated or Fight.is_out_of_breath(fight.protagonist.breath_dice)
	var monster_out: bool = fight.monster_incapacitated or fight.monster.is_out_of_breath()
	if player_out and monster_out: return Fight.Outcome.DRAW
	if player_out: return Fight.Outcome.LOST
	if monster_out: return Fight.Outcome.WON
	return Fight.Outcome.ONGOING
