class_name ForcingWeaponTactic
extends WeaponTactic

## Strikes with the best die it is willing to force; by default never forces

## How far above the wield score a die may be to still be forced
@export_range(0, 12) var max_overshoot: int = 0
## Also strike on marked faces within the wield score (marks the next higher face)
@export var force_marked_faces: bool = false

func choose_weapon_die(side: FightSide, foe: FightSide) -> Die:
	var chosen: Die = null
	for die: Die in side.weapon_dice:
		var overshoot: int = side.get_weapon_overshoot(die)
		if overshoot > max_overshoot: continue
		if overshoot == 0 and side.marked_faces.has(die.result) and not force_marked_faces: continue
		if not chosen or WeaponTactic.rank(die, foe) > WeaponTactic.rank(chosen, foe): chosen = die
	return chosen
