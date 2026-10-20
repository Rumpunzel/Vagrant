class_name InjuryStep
extends ExchangeStep

func applies(fight: Fight) -> bool: return get_side(fight).injury_taken > 0

## Injuries have their own display, so this tells nothing
func enter(fight: Fight) -> String:
	get_actor(fight).suffer_injury(Injury.new(get_side(fight).injury_taken))
	return ""
