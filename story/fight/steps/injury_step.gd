class_name InjuryStep
extends ExchangeStep

func applies(fight: Fight) -> bool: return get_side(fight).injury_taken > 0

## Injuries have their own display, so this tells nothing
func enter(fight: Fight) -> String:
	var injury: Injury = Injury.new(get_side(fight).injury_taken)
	if is_player(): fight.protagonist.suffer_injury(injury)
	else: fight.monster.suffer_injury(injury)
	return ""
