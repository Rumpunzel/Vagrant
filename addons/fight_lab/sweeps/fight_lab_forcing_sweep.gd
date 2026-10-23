@tool
class_name FightLabForcingSweep
extends FightLabSweep

## Sets how far above its wield score the player forces their weapon or shield

enum Gear {
	WEAPON,
	SHIELD,
}

@export var gear: Gear = Gear.WEAPON

func get_label() -> String: return "Max overshoot (%s)" % ("weapon" if gear == Gear.WEAPON else "shield")

func get_values() -> Array[int]:
	var values: Array[int] = []
	values.assign(range(maxi(from, 0), to + 1))
	return values

func apply(value: int, matchup: FightLabMatchup) -> void:
	var strategy: FightLabStrategy = matchup.strategy.duplicate()
	if gear == Gear.WEAPON:
		var weapon_tactic: ForcingWeaponTactic = strategy.weapon_tactic.duplicate() if strategy.weapon_tactic is ForcingWeaponTactic else ForcingWeaponTactic.new()
		weapon_tactic.max_overshoot = value
		strategy.weapon_tactic = weapon_tactic
	else:
		var shield_tactic: ForcingShieldTactic = strategy.shield_tactic.duplicate() if strategy.shield_tactic is ForcingShieldTactic else ForcingShieldTactic.new()
		shield_tactic.max_overshoot = value
		strategy.shield_tactic = shield_tactic
	matchup.strategy = strategy
