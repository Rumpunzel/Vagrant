class_name ShieldStep
extends ExchangeStep

## This side's raised shield: tells what it took off the blow and marks what raising it cost

func applies(fight: Fight) -> bool: return get_side(fight).raises_shield

func enter(fight: Fight) -> String:
	var shield_side: FightSide = get_side(fight)
	var shield: Shield = get_shield(fight)
	var face: int = shield_side.shield_dice[0].result
	var blocked: String = "%d off %s blow" % [shield_side.shield_blocked, get_foe_owner(fight)]
	if shield_side.shield_strain == FightSide.Strain.OVERREACH:
		shield.ruin()
		return "%s %s %s %s up: %s. %s %s is ruined." % [get_subject(fight), pick("force", "forces"), pick("your", "its"), shield.get_equipment_name(), blocked, get_owner(fight).capitalize(), shield.get_equipment_name()]
	return "%s %s %s %s: %s. %s" % [get_subject(fight), pick("raise", "raises"), pick("your", "its"), shield.get_equipment_name(), blocked, _mark(shield, face, get_owner(fight))]
