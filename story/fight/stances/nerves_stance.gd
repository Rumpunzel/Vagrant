class_name NervesStance
extends FightStance

func get_impairments(target: CharacterAttribute, margin: int) -> Dictionary[CharacterAttribute, int]:
	assert(target, "Threatening with Nerves requires a target attribute")
	return {target: margin}
