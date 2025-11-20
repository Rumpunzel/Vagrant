class_name AdventureInjuryConsequence
extends AdventureConsequence

func resolve(protagonist: Character, damage: int) -> void:
	var injury: Injury = Injury.new(damage)
	protagonist.suffer_injury(injury)
