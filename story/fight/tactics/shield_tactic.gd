@abstract
class_name ShieldTactic
extends Resource

## How a fighter decides whether to raise their shield, before knowing the foe's blow

## [param overshoot] is how far [param side]'s shield die is above its wield score: what raising it costs in threat
@abstract func raises(side: FightSide, overshoot: int) -> bool
