class_name RecklessShieldTactic
extends ShieldTactic

## Raises the shield against every blow, forcing it if it has to

func raises(_side: FightSide, _damage: int, _forced: bool) -> bool: return true
