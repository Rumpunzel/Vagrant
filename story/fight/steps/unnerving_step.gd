class_name UnnervingStep
extends ExchangeStep

## Tells how the foe's Nerves impaired this side
func enter(fight: Fight) -> String:
	var impairments: Dictionary[CharacterAttribute, int] = get_side(fight).impairments
	if impairments.is_empty(): return ""
	var parts: Array[String] = []
	for attribute: CharacterAttribute in impairments: parts.append("−%d %s" % [impairments[attribute], Fight.describe_attribute(attribute)])
	var monster_name: String = fight.monster.get_monster_name()
	return pick("The %s unnerves you (%s)." % [monster_name, ", ".join(parts)], "You unnerve the %s (%s)." % [monster_name, ", ".join(parts)])
