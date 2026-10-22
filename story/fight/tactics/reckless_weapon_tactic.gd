class_name RecklessWeaponTactic
extends WeaponTactic

## Always strikes with the best die, forcing the weapon if it has to

func choose_weapon_die(side: FightSide, foe: FightSide) -> Die:
	var chosen: Die = null
	for die: Die in side.weapon_dice:
		if not chosen or WeaponTactic.rank(die, foe) > WeaponTactic.rank(chosen, foe): chosen = die
	return chosen
