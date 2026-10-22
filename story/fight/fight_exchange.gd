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
	for side: FightSide in [first, second]: side.threat = get_highest_result(side.breath_dice)
	for side: FightSide in [first, second]:
		var vantage: int = _get_stance_value(side)
		if vantage > 0: _impair(get_foe(side), side.get_fight_stance().get_impairments(side.nerves_target, vantage))
	for side: FightSide in [first, second]: _check_dice(side, get_foe(side))
	for side: FightSide in [first, second]: get_foe(side).injury_taken = _get_damage(side, get_foe(side))

## The defender's shield takes its result off [param damage] if raised; returns what gets through
static func _raise_shield(defender: FightSide, damage: int) -> int:
	defender.blow = maxi(damage, 0)
	if defender.shield_dice.is_empty() or damage <= 0: return damage
	var shield_die: Die = defender.shield_dice[0]
	var forced: bool = shield_die.result > defender.get_shield_wield_score()
	match defender.shield_use:
		FightSide.ShieldUse.LOWER: return damage
		FightSide.ShieldUse.AUTO:
			var tactic: ShieldTactic = defender.shield_tactic if defender.shield_tactic else CautiousShieldTactic.new()
			if not tactic.raises(defender, damage, forced): return damage
	defender.raises_shield = true
	defender.shield_blocked = mini(shield_die.result, damage)
	if forced: defender.shield_strain = FightSide.Strain.OVERREACH
	elif defender.shield_marked_faces.has(shield_die.result): defender.shield_strain = FightSide.Strain.MARKED_FACE
	return damage - defender.shield_blocked

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

func _check_dice(side: FightSide, foe: FightSide) -> void:
	var stance_score: int = side.get_score(side.stance)
	side.lost_breath_dice.assign(side.breath_dice.filter(func(die: Die) -> bool: return die.result > stance_score))
	if side.has_natural_weapons:
		side.usable_weapon_dice.assign(side.weapon_dice)
	elif side.is_armed():
		var weapon_die: Die = side.chosen_weapon_die
		if not weapon_die and not side.holds_back: weapon_die = (side.weapon_tactic if side.weapon_tactic else CautiousWeaponTactic.new()).choose_weapon_die(side, foe)
		if weapon_die:
			side.usable_weapon_dice.assign([weapon_die])
			if weapon_die.result > side.get_wield_score(): side.weapon_strain = FightSide.Strain.OVERREACH
			elif side.marked_faces.has(weapon_die.result): side.weapon_strain = FightSide.Strain.MARKED_FACE
		for die: Die in side.weapon_dice:
			if die == weapon_die: continue
			if side.is_free_weapon_die(die): side.spare_weapon_dice.append(die)
			else: side.failed_weapon_dice.append(die)
	# Only the die struck with meets the foe's armour
	side.blocked_weapon_dice.assign(side.usable_weapon_dice.filter(func(die: Die) -> bool: return foe.armor_blocks.has(die.result)))
	var damaging_dice: Array[Die] = []
	damaging_dice.assign(side.usable_weapon_dice.filter(func(die: Die) -> bool: return not side.blocked_weapon_dice.has(die)))
	side.weapon_damage = get_highest_result(damaging_dice)

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
	damage = _raise_shield(foe, damage)
	var injury: int = maxi(damage - foe.damage_reduction, 0)
	foe.damage_prevented = maxi(damage, 0) - injury
	return injury

static func get_highest_result(dice: Array[Die]) -> int:
	var highest_result: int = 0
	for die: Die in dice: highest_result = maxi(highest_result, die.result)
	return highest_result
