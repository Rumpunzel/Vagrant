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
		if side.fleeing: side.stance = Rules.AGILITY
		elif not side.is_armed(): side.stance = Rules.STRENGTH
	for side: FightSide in [first, second]: _raise_shield(side, get_foe(side))
	for side: FightSide in [first, second]: side.threat = _get_highest_result(side.breath_dice, side)
	for side: FightSide in [first, second]:
		var margin: int = _get_margin(side)
		if margin > 0: _impair(get_foe(side), side.get_fight_stance().get_impairments(side.nerves_target, margin))
	for side: FightSide in [first, second]: _check_dice(side, get_foe(side))
	for side: FightSide in [first, second]: get_foe(side).injury_taken = _get_damage(side, get_foe(side))

## Lowers the foe's highest die (breath or weapon; a tie goes to the weapon) by the shield's result.
## Losses, wielding and armour still use the rolled face; threat and damage use the lowered one.
func _raise_shield(side: FightSide, foe: FightSide) -> void:
	if side.shield_dice.is_empty(): return
	var shield_die: Die = side.shield_dice[0]
	if shield_die.result > side.get_score(side.shield_wield_attribute if side.shield_wield_attribute else Rules.STRENGTH):
		side.failed_shield_dice.assign(side.shield_dice)
		return
	if side.shield_marked_faces.has(shield_die.result): return
	var target: Die = null
	for die: Die in foe.weapon_dice: if not target or die.result > target.result: target = die
	for die: Die in foe.breath_dice: if not target or die.result > target.result: target = die
	if not target: return
	side.shield_target = target
	side.shield_value = shield_die.result
	foe.reduced_results[target] = maxi(foe.get_result(target) - shield_die.result, 0)

## Applied before dice are checked, so it can cost the foe breath dice or their weapon
func _impair(foe: FightSide, impairments: Dictionary[CharacterAttribute, int]) -> void:
	for attribute: CharacterAttribute in impairments: foe.impairments[attribute] = foe.impairments.get(attribute, 0) + impairments[attribute]

## How much [param side] won the threat by; on a tie its full threat, 0 if it lost
func _get_margin(side: FightSide) -> int:
	var foe_threat: int = get_foe(side).threat
	if side.threat == foe_threat: return side.threat
	return maxi(side.threat - foe_threat, 0)

func _check_dice(side: FightSide, foe: FightSide) -> void:
	var stance_score: int = side.get_score(side.stance)
	side.lost_breath_dice.assign(side.breath_dice.filter(func(die: Die) -> bool: return die.result > stance_score))
	if side.has_natural_weapons:
		side.usable_weapon_dice.assign(side.weapon_dice)
	else:
		var wield_score: int = side.get_score(side.wield_attribute if side.wield_attribute else Rules.STRENGTH)
		side.usable_weapon_dice.assign(side.weapon_dice.filter(func(die: Die) -> bool: return die.result <= wield_score))
		side.failed_weapon_dice.assign(side.weapon_dice.filter(func(die: Die) -> bool: return die.result > wield_score))
	# Only wielded dice meet the foe's armour
	side.blocked_weapon_dice.assign(side.usable_weapon_dice.filter(func(die: Die) -> bool: return foe.armor_blocks.has(die.result)))
	var damaging_dice: Array[Die] = []
	damaging_dice.assign(side.usable_weapon_dice.filter(func(die: Die) -> bool: return not side.blocked_weapon_dice.has(die) and not side.marked_faces.has(die.result)))
	side.weapon_damage = _get_highest_result(damaging_dice, side)

func _get_damage(side: FightSide, foe: FightSide) -> int:
	var damage: int = side.weapon_damage
	# Unarmed sides always threaten with Guts, which is how they deal the difference
	var margin: int = _get_margin(side)
	if margin > 0: damage = side.get_fight_stance().modify_damage_dealt(damage, margin)
	var foe_margin: int = _get_margin(foe)
	if foe_margin > 0: damage = foe.get_fight_stance().modify_damage_taken(damage, foe_margin)
	return maxi(damage - foe.damage_reduction, 0)

## Highest result among [param dice], counting the foe's shield if [param side] is given
static func _get_highest_result(dice: Array[Die], side: FightSide = null) -> int:
	var highest_result: int = 0
	for die: Die in dice: highest_result = maxi(highest_result, side.get_result(die) if side else die.result)
	return highest_result
