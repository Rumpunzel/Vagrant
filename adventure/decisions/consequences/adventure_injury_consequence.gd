class_name AdventureInjuryConsequence
extends AdventureConsequence

func resolve(protagonist: Character, damage: int) -> void:
	# E.g. a fight lost on arrival or on a tie has no margin to injure with
	if damage <= 0: return
	var injury: Injury = Injury.new(damage)
	protagonist.suffer_injury(injury)
