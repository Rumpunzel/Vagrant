class_name VantageStep
extends ExchangeStep

## What this side's stance did to the damage with its vantage; Nerves tells its part in [UnnervingStep]
func enter(fight: Fight) -> String:
	var vantage_side: FightSide = get_side(fight)
	var lines: Array[String] = []
	if vantage_side.damage_added > 0: lines.append("%s %s %s advantage: +%d to %s blow." % [get_subject(fight), pick("press", "presses"), pick("your", "its"), vantage_side.damage_added, pick("your", "its")])
	if vantage_side.damage_avoided > 0: lines.append("%s %s %d of %s blow." % [get_subject(fight), pick("dodge", "dodges"), vantage_side.damage_avoided, get_foe_owner(fight)])
	return _join(lines)
