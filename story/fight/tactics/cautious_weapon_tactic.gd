class_name CautiousWeaponTactic
extends WeaponTactic

## Never forces the weapon: the best die that needs no forcing, or none

func choose_weapon_die(side: FightSide, foe: FightSide) -> Die:
	var chosen: Die = null
	for die: Die in side.weapon_dice:
		if not side.is_free_weapon_die(die): continue
		if not chosen or WeaponTactic.rank(die, foe) > WeaponTactic.rank(chosen, foe): chosen = die
	return chosen
