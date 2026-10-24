@abstract
class_name WeaponTactic
extends Resource

## How a fighter decides which weapon die to strike with

## The die to strike with (forced if it needs to be), or null to hold back. Decided before the threat,
## so [param side]'s scores don't count the foe's Nerves yet.
@abstract func choose_weapon_die(side: FightSide, foe: FightSide) -> Die

## How good striking with [param die] is: one the foe's armour doesn't block (that would mark the weapon), then the highest
static func rank(die: Die, foe: FightSide) -> int:
	return 0 if foe.armor_blocks.has(die.result) else die.result
