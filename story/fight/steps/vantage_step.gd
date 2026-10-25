class_name VantageStep
extends ResolutionStep

## What this side's stance did to the damage with its vantage; Nerves tells its part in [UnnervingStep]
func enter(fight: Fight) -> String:
	var vantage_side: FightSide = get_side(fight)
	var lines: Array[String] = []
	if vantage_side.damage_added > 0: lines.append("%s %s %s advantage: +%d to %s blow." % [get_subject(fight), pick(fight, "press", "presses"), get_pronoun(fight), vantage_side.damage_added, get_pronoun(fight)])
	if vantage_side.damage_avoided > 0: lines.append("%s %s %d of %s blow." % [get_subject(fight), pick(fight, "dodge", "dodges"), vantage_side.damage_avoided, get_foe_owner(fight)])
	if not lines.is_empty(): lines.append(describe_vantage_ability(fight))
	return _join(lines)
