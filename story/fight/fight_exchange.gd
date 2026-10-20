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
	for side: FightSide in [first, second]: side.threat = get_highest_result(side.breath_dice, side)
	for side: FightSide in [first, second]:
		var vantage: int = _get_stance_value(side)
		if vantage > 0: _impair(get_foe(side), side.get_fight_stance().get_impairments(side.nerves_target, vantage))
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

## What [param side]'s stance works with: its vantage, or on a tie its full threat
func _get_stance_value(side: FightSide) -> int:
	if side.threat == get_foe(side).threat: return side.threat
	return _get_vantage(side)

## How much [param side] won the threat by, as its abilities count it; 0 on a tie or when it lost
func _get_vantage(side: FightSide) -> int:
	var vantage: int = maxi(side.threat - get_foe(side).threat, 0)
	if vantage == 0: return 0
	for ability: Ability in side.abilities: vantage = ability.modify_vantage(vantage)
	return vantage

## Of several weapon dice only one counts: the one dealing the most damage, then the one harming the weapon least
func _choose_weapon_die(side: FightSide, foe: FightSide, wield_score: int) -> Die:
	var chosen: Die = null
	for die: Die in side.weapon_dice:
		if not chosen: chosen = die
		else:
			var damage: int = _get_weapon_die_damage(die, side, foe, wield_score)
			var chosen_damage: int = _get_weapon_die_damage(chosen, side, foe, wield_score)
			var harm: int = _get_weapon_die_harm(die, side, foe, wield_score)
			var chosen_harm: int = _get_weapon_die_harm(chosen, side, foe, wield_score)
			if damage > chosen_damage or (damage == chosen_damage and (harm < chosen_harm or (harm == chosen_harm and die.result < chosen.result))): chosen = die
	return chosen

## Marked faces and results the foe's armour blocks deal nothing
func _get_weapon_die_damage(die: Die, side: FightSide, foe: FightSide, wield_score: int) -> int:
	if die.result > wield_score or foe.armor_blocks.has(die.result) or side.marked_faces.has(die.result): return 0
	return die.result

## 0: harmless, 1: marks the weapon (failing to wield it, or armour blocking the die), 2: ruins it (marking a marked face)
func _get_weapon_die_harm(die: Die, side: FightSide, foe: FightSide, wield_score: int) -> int:
	if die.result <= wield_score and not foe.armor_blocks.has(die.result): return 0
	return 2 if side.marked_faces.has(die.result) else 1

func _check_dice(side: FightSide, foe: FightSide) -> void:
	var stance_score: int = side.get_score(side.stance)
	side.lost_breath_dice.assign(side.breath_dice.filter(func(die: Die) -> bool: return die.result > stance_score))
	if side.has_natural_weapons:
		side.usable_weapon_dice.assign(side.weapon_dice)
	elif side.is_armed():
		var wield_score: int = side.get_score(side.wield_attribute if side.wield_attribute else Rules.STRENGTH)
		var weapon_die: Die = _choose_weapon_die(side, foe, wield_score)
		side.spare_weapon_dice.assign(side.weapon_dice.filter(func(die: Die) -> bool: return die != weapon_die))
		if weapon_die.result <= wield_score: side.usable_weapon_dice.assign([weapon_die])
		else: side.failed_weapon_dice.assign([weapon_die])
	# Only wielded dice meet the foe's armour
	side.blocked_weapon_dice.assign(side.usable_weapon_dice.filter(func(die: Die) -> bool: return foe.armor_blocks.has(die.result)))
	var damaging_dice: Array[Die] = []
	damaging_dice.assign(side.usable_weapon_dice.filter(func(die: Die) -> bool: return not side.blocked_weapon_dice.has(die) and not side.marked_faces.has(die.result)))
	side.weapon_damage = get_highest_result(damaging_dice, side)

func _get_damage(side: FightSide, foe: FightSide) -> int:
	var damage: int = side.weapon_damage
	# Unarmed sides always threaten with Guts, which is how they deal the difference
	var vantage: int = _get_stance_value(side)
	if vantage > 0:
		var dealt: int = side.get_fight_stance().modify_damage_dealt(damage, vantage)
		side.damage_added = dealt - damage
		damage = dealt
	var foe_vantage: int = _get_stance_value(foe)
	if foe_vantage > 0:
		var taken: int = foe.get_fight_stance().modify_damage_taken(damage, foe_vantage)
		foe.damage_avoided = maxi(damage, 0) - maxi(taken, 0)
		damage = taken
	var injury: int = maxi(damage - foe.damage_reduction, 0)
	foe.damage_prevented = maxi(damage, 0) - injury
	return injury

## Highest result among [param dice], counting the foe's shield if [param side] is given
static func get_highest_result(dice: Array[Die], side: FightSide = null) -> int:
	var highest_result: int = 0
	for die: Die in dice: highest_result = maxi(highest_result, side.get_result(die) if side else die.result)
	return highest_result
