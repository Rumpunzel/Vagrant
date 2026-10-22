class_name WeaponChoiceStep
extends ExchangeStep

## Where the player decides which weapon die to strike with, if forcing the weapon is possible or they asked to choose.
## Shown and resolved by whoever presents the exchange, through [method Fight.resolve_player_choice].

func applies(fight: Fight) -> bool:
	if not is_player(): return false
	var weapon_side: FightSide = get_side(fight)
	var weapon: Weapon = get_weapon(fight)
	if not weapon or not weapon.is_usable() or weapon_side.has_natural_weapons: return false
	if fight.always_choose_weapon_die and weapon_side.weapon_dice.size() > 1: return true
	return weapon_side.weapon_dice.any(func(die: Die) -> bool: return not weapon_side.is_free_weapon_die(die))

func enter(_fight: Fight) -> String: return ""

## Every rolled weapon die, each with what striking with it costs
func get_options(fight: Fight) -> Array[Die]: return get_side(fight).weapon_dice
