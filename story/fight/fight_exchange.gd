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
	for side: FightSide in [first, second]: _commit(side, get_foe(side))
	for side: FightSide in [first, second]: side.threat = _get_threat(side)
	for side: FightSide in [first, second]:
		var vantage: int = _get_stance_value(side)
		if vantage > 0: _impair(get_foe(side), side.get_fight_stance().get_impairments(side.nerves_target, vantage))
	for side: FightSide in [first, second]: _check_dice(side, get_foe(side))
	for side: FightSide in [first, second]: get_foe(side).injury_taken = _get_damage(side, get_foe(side))

## Before the threat: the weapon die to strike with and whether the shield is raised, judged by scores the foe's Nerves haven't touched
func _commit(side: FightSide, foe: FightSide) -> void:
	if side.is_armed() and not side.has_natural_weapons:
		var weapon_die: Die = side.chosen_weapon_die
		if not weapon_die and not side.holds_back: weapon_die = (side.weapon_tactic if side.weapon_tactic else ForcingWeaponTactic.new()).choose_weapon_die(side, foe)
		if weapon_die:
			side.usable_weapon_dice.assign([weapon_die])
			side.weapon_overshoot = side.get_weapon_overshoot(weapon_die)
			if side.weapon_overshoot > 0: side.weapon_strain = FightSide.Strain.OVERREACH
			elif side.marked_faces.has(weapon_die.result): side.weapon_strain = FightSide.Strain.MARKED_FACE
		for die: Die in side.weapon_dice:
			if die == weapon_die: continue
			if side.is_free_weapon_die(die): side.spare_weapon_dice.append(die)
			else: side.failed_weapon_dice.append(die)
	if not side.shield_dice.is_empty():
		var overshoot: int = side.get_shield_overshoot()
		var raises: bool = side.shield_use == FightSide.ShieldUse.RAISE
		if side.shield_use == FightSide.ShieldUse.AUTO: raises = (side.shield_tactic if side.shield_tactic else ForcingShieldTactic.new()).raises(side, overshoot)
		if raises:
			side.raises_shield = true
			side.shield_overshoot = overshoot

## The highest of the breath dice and the free weapon and shield dice used, minus what forcing costs; may be below 0
static func _get_threat(side: FightSide) -> int:
	var dice: Array[Die] = side.breath_dice.duplicate()
	if not side.has_natural_weapons and not side.usable_weapon_dice.is_empty() and side.weapon_strain == FightSide.Strain.NONE: dice.append(side.usable_weapon_dice[0])
	if side.raises_shield and side.shield_overshoot == 0: dice.append(side.shield_dice[0])
	return get_highest_result(dice) - side.weapon_overshoot - side.shield_overshoot

## The raised shield takes its result off [param damage]; returns what gets through
static func _raise_shield(defender: FightSide, damage: int) -> int:
	defender.blow = maxi(damage, 0)
	if not defender.raises_shield or damage <= 0: return damage
	defender.shield_blocked = mini(defender.shield_dice[0].result, damage)
	return damage - defender.shield_blocked

## Nerves: dice rolled or wielded with an impaired attribute are judged against its score minus the vantage
func _impair(foe: FightSide, impairments: Dictionary[CharacterAttribute, int]) -> void:
	for attribute: CharacterAttribute in impairments: foe.impairments[attribute] = foe.impairments.get(attribute, 0) + impairments[attribute]

## What [param side]'s stance works with: its vantage, or on a tie its full threat (if above 0)
func _get_stance_value(side: FightSide) -> int:
	if side.threat == get_foe(side).threat: return maxi(side.threat, 0)
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
	elif not side.usable_weapon_dice.is_empty() and _is_dropped(side, side.wield_attribute, side.usable_weapon_dice[0]):
		side.weapon_dropped = true
		side.usable_weapon_dice.clear()
	if side.raises_shield and _is_dropped(side, side.shield_wield_attribute, side.shield_dice[0]):
		side.shield_dropped = true
		side.raises_shield = false
	# Only the die struck with meets the foe's armour
	side.blocked_weapon_dice.assign(side.usable_weapon_dice.filter(func(die: Die) -> bool: return foe.armor_blocks.has(die.result)))
	var damaging_dice: Array[Die] = []
	damaging_dice.assign(side.usable_weapon_dice.filter(func(die: Die) -> bool: return not side.blocked_weapon_dice.has(die)))
	side.weapon_damage = get_highest_result(damaging_dice)

## Gear wielded with an attribute the foe's Nerves impaired is dropped if its die came up above what is left of that score
static func _is_dropped(side: FightSide, wield_attribute: CharacterAttribute, die: Die) -> bool:
	var attribute: CharacterAttribute = wield_attribute if wield_attribute else Rules.STRENGTH
	return side.impairments.has(attribute) and die.result > side.get_score(attribute)

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
