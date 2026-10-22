class_name ArmorChoiceStep
extends ExchangeStep

## Where the player decides which piece of their armour takes a blocked blow, whenever there is more than one way to take it.
## Shown by whoever presents the exchange, who stores each pick in [member Fight.armor_picks].

func applies(fight: Fight) -> bool: return is_player() and get_undecided_die(fight) != null

func enter(_fight: Fight) -> String: return ""

## The next blocked foe die the player still has to decide on, null when none is left
func get_undecided_die(fight: Fight) -> Die:
	for blocked_die: Die in get_foe_side(fight).blocked_weapon_dice:
		if fight.armor_picks.has(blocked_die): continue
		if ArmorPick.get_options(get_actor(fight).armor, blocked_die.result).size() > 1: return blocked_die
	return null
