@tool
class_name HighestBreathDieLossAbility
extends Ability

## Of all breath dice lost, only the highest is; on equal results the smaller die
func modify_lost_breath_dice(lost_breath_dice: Array[Die]) -> Array[Die]:
	var highest_lost_breath_die: Die = null
	for lost_breath_die: Die in lost_breath_dice:
		var is_higher: bool = false
		if not highest_lost_breath_die: is_higher = true
		elif lost_breath_die.result > highest_lost_breath_die.result: is_higher = true
		elif lost_breath_die.result == highest_lost_breath_die.result and lost_breath_die.die_type.faces < highest_lost_breath_die.die_type.faces: is_higher = true
		if is_higher: highest_lost_breath_die = lost_breath_die
	if highest_lost_breath_die: return [highest_lost_breath_die]
	return lost_breath_dice
