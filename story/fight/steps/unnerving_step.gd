class_name UnnervingStep
extends ExchangeStep

## Tells how the foe's Nerves impaired this side, and drops the gear it made this side lose for the rest of the fight
func enter(fight: Fight) -> String:
	var unnerved_side: FightSide = get_side(fight)
	var impairments: Dictionary[CharacterAttribute, int] = unnerved_side.impairments
	if impairments.is_empty(): return ""
	var parts: Array[String] = []
	for attribute: CharacterAttribute in impairments: parts.append("−%d %s" % [impairments[attribute], Fight.describe_attribute(attribute)])
	var lines: Array[String] = ["%s %s %s (%s)." % [get_foe_subject(fight), pick_foe(fight, "unnerve", "unnerves"), get_object(fight), ", ".join(parts)]]
	if unnerved_side.weapon_dropped: lines.append(_drop(get_weapon(fight), fight))
	if unnerved_side.shield_dropped: lines.append(_drop(get_shield(fight), fight))
	return _join(lines)

func _drop(equipment: Equipment, fight: Fight) -> String:
	equipment.dropped = true
	return "%s %s %s %s." % [get_subject(fight), pick(fight, "drop", "drops"), get_pronoun(fight), equipment.get_equipment_name()]
