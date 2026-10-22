class_name ShieldChoiceStep
extends ExchangeStep

## Where the player decides whether to raise their shield against the foe's blow.
## Shown and resolved by whoever presents the exchange, through [method Fight.resolve_player_choice].

func applies(fight: Fight) -> bool:
	if not is_player(): return false
	var shield: Shield = get_shield(fight)
	return shield and shield.is_usable() and not get_side(fight).shield_dice.is_empty() and get_side(fight).blow > 0

func enter(_fight: Fight) -> String: return ""
