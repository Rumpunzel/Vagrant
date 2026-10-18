@abstract
class_name WeaponModifier
extends Resource

## Shapes a weapon when a character or monster gets it, e.g. "battered" or (later) "poisoned".
## Lets one weapon profile serve many monster types without duplicated weapon resources.

@abstract func modify(weapon: Weapon) -> void
