class_name FightExchange
extends RefCounted

## Resolves one exchange between two sides whose dice are already rolled.
## Pure rules: no rolling, no side effects outside the two [FightSide]s.

var first: FightSide
var second: FightSide

func _init(first_side: FightSide, second_side: FightSide) -> void:
	assert(first_side and second_side)
	first = first_side
	second = second_side
	_resolve()

func get_foe(side: FightSide) -> FightSide:
	assert(side == first or side == second)
	return second if side == first else first

func _resolve() -> void:
	for side: FightSide in [first, second]:
		# Fleeing is always a Blood roll, unarmed violence always Guts
		if side.fleeing: side.stance = Rules.AGILITY
		elif not side.is_armed(): side.stance = Rules.STRENGTH
	for side: FightSide in [first, second]: side.threat = _get_highest_result(side.breath_dice)
	for side: FightSide in [first, second]:
		var margin: int = _get_margin(side)
		if margin > 0: _impair(get_foe(side), side.get_fight_stance().get_impairments(side.nerves_target, margin))
	for side: FightSide in [first, second]: _check_dice(side)
	for side: FightSide in [first, second]: get_foe(side).injury_taken = _get_damage(side, get_foe(side))

## Applied before dice are checked, so it can cost the foe breath dice or their weapon
func _impair(foe: FightSide, impairments: Dictionary[CharacterAttribute, int]) -> void:
	for attribute: CharacterAttribute in impairments: foe.impairments[attribute] = foe.impairments.get(attribute, 0) + impairments[attribute]

## How much [param side] won the threat by; on a tie its full threat, 0 if it lost
func _get_margin(side: FightSide) -> int:
	var foe_threat: int = get_foe(side).threat
	if side.threat == foe_threat: return side.threat
	return maxi(side.threat - foe_threat, 0)

func _check_dice(side: FightSide) -> void:
	var stance_score: int = side.get_score(side.stance)
	side.lost_breath_dice.assign(side.breath_dice.filter(func(die: Die) -> bool: return die.result > stance_score))
	if side.has_natural_weapons:
		# Natural weapons always hit, even with dice the side loses
		side.usable_weapon_dice.assign(side.weapon_dice)
		side.weapon_damage = _get_highest_result(side.usable_weapon_dice)
		return
	var wield_score: int = side.get_score(side.wield_attribute if side.wield_attribute else Rules.STRENGTH)
	side.usable_weapon_dice.assign(side.weapon_dice.filter(func(die: Die) -> bool: return die.result <= wield_score))
	side.failed_weapon_dice.assign(side.weapon_dice.filter(func(die: Die) -> bool: return die.result > wield_score))
	# Marked faces are crossed out and deal no damage
	var damaging_dice: Array[Die] = []
	damaging_dice.assign(side.usable_weapon_dice.filter(func(die: Die) -> bool: return not side.marked_faces.has(die.result)))
	side.weapon_damage = _get_highest_result(damaging_dice)

func _get_damage(side: FightSide, foe: FightSide) -> int:
	var damage: int = side.weapon_damage
	# Unarmed sides always threaten with Guts, which is how they deal the difference
	var margin: int = _get_margin(side)
	if margin > 0: damage = side.get_fight_stance().modify_damage_dealt(damage, margin)
	var foe_margin: int = _get_margin(foe)
	if foe_margin > 0: damage = foe.get_fight_stance().modify_damage_taken(damage, foe_margin)
	return maxi(damage, 0)

static func _get_highest_result(dice: Array[Die]) -> int:
	var highest_result: int = 0
	for die: Die in dice: highest_result = maxi(highest_result, die.result)
	return highest_result
