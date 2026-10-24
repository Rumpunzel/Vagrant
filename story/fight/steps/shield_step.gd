class_name ShieldStep
extends ExchangeStep

## This side's raised shield: tells what it took off the blow and marks it for blocking

func applies(fight: Fight) -> bool: return get_side(fight).raises_shield and get_side(fight).shield_blocked > 0

func enter(fight: Fight) -> String:
	var shield_side: FightSide = get_side(fight)
	var shield: Shield = get_shield(fight)
	var face: int = shield_side.shield_dice[0].result
	return "%s %s takes %d off %s blow. %s" % [Fight.capitalize_first(get_owner(fight)), shield.get_equipment_name(), shield_side.shield_blocked, get_foe_owner(fight), _mark(shield, face, get_owner(fight))]
