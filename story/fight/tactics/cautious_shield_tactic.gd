class_name CautiousShieldTactic
extends ShieldTactic

## Raises the shield against every blow, unless it would have to be forced (which ruins it)

func raises(_side: FightSide, _damage: int, forced: bool) -> bool: return not forced
