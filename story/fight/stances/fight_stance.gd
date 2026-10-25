@abstract
class_name FightStance
extends Resource

## What threatening with an attribute does when its side has [param vantage]: how much it won the threat by
## (on a tie, the side's full threat, which abilities do not change).
## Hooks are only called with a vantage > 0 and do nothing by default.

## Shown in the stance selection, e.g. "Charge with might and ferocity!"
@export_multiline var description: String

## Attribute -> reduction applied to the foe for this exchange, before breath dice and weapons are checked.
## [param target] is the foe attribute the threatening side chose, if any.
## Must not reference fight classes: attributes are preloaded by [code]Rules[/code], which they depend on.
func get_impairments(_target: CharacterAttribute, _vantage: int) -> Dictionary[CharacterAttribute, int]: return {}

func modify_damage_dealt(damage: int, _vantage: int) -> int: return damage
func modify_damage_taken(damage: int, _vantage: int) -> int: return damage
