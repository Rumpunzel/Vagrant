class_name ForcingShieldTactic
extends ShieldTactic

## Raises the shield unless it would have to be forced further than it is willing to; by default never forces

## How far above the wield score the shield die may be to still be forced
@export_range(0, 12) var max_overshoot: int = 0

func raises(_side: FightSide, overshoot: int) -> bool: return overshoot <= max_overshoot
