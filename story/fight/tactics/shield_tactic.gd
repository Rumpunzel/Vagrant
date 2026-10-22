@abstract
class_name ShieldTactic
extends Resource

## How a fighter decides whether to raise their shield against a blow

## [param damage] is the blow coming at [param side]; [param forced] means its shield die is above its wield score
@abstract func raises(side: FightSide, damage: int, forced: bool) -> bool
