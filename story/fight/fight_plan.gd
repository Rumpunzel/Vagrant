class_name FightPlan
extends RefCounted

## What one side brings to an exchange before anything is rolled: the player's choices (see [method FightRequest.get_plan]),
## a monster's habits (see [method Monster.get_fight_plan]), or a simulated fighter's strategy.

var actor: Actor
var stance: CharacterAttribute
## Breath dice to roll
var breath_dice: Dictionary[DieType, int]
## Foe attribute to impair when threatening with Nerves
var nerves_target: CharacterAttribute
## null: unarmed (or natural weapons)
var weapon: Weapon
var fleeing: bool = false
## How the side commits and picks armour when nobody asks the player; none: never forcing, sparing armour
var weapon_tactic: WeaponTactic
var shield_tactic: ShieldTactic
var armor_tactic: ArmorTactic

func _init(for_actor: Actor, with_stance: CharacterAttribute, with_breath_dice: Dictionary[DieType, int]) -> void:
	assert(for_actor and with_stance)
	actor = for_actor
	stance = with_stance
	breath_dice = with_breath_dice

## Rolls the side's breath, weapon and shield dice; [param rolled_breath_dice] instead of rolling the breath dice (the player's roll)
func roll(rolled_breath_dice: Array[Die] = []) -> FightSide:
	var dice: Array[Die] = rolled_breath_dice if not rolled_breath_dice.is_empty() else DiceRoller.roll_dice(DiceRoller.generate_dice_pool(breath_dice))
	var scores: Dictionary[CharacterAttribute, int] = {}
	for attribute: CharacterAttribute in Rules.ATTRIBUTES: scores[attribute] = actor.get_score(attribute)
	var side: FightSide = FightSide.new(stance, dice, scores, [], fleeing, nerves_target)
	side.abilities = actor.get_abilities()
	if actor.has_natural_weapons():
		side.weapon_dice = dice
		side.has_natural_weapons = true
	elif weapon:
		var extra_dice: int = 0
		for ability: Ability in side.abilities: extra_dice += ability.get_extra_weapon_dice()
		side.weapon = weapon
		side.weapon_dice = _roll_dice(weapon.get_die_type(), 1 + extra_dice)
		side.wield_attribute = weapon.get_wield_attribute()
		side.marked_faces = weapon.marked_faces.duplicate()
	side.armor_blocks = Armor.get_blocked_results(actor.armor)
	side.damage_reduction = Armor.get_total_damage_reduction(actor.armor)
	var shield: Shield = Shield.get_first_usable(actor.shields)
	if shield:
		side.shield = shield
		side.shield_dice = _roll_dice(shield.get_die_type(), 1)
		side.shield_wield_attribute = shield.get_wield_attribute()
		side.shield_marked_faces = shield.marked_faces.duplicate()
	side.weapon_tactic = weapon_tactic
	side.shield_tactic = shield_tactic
	side.armor_tactic = armor_tactic
	return side

static func _roll_dice(die_type: DieType, amount: int) -> Array[Die]:
	var dice: Array[Die] = []
	for _index: int in amount:
		var die: Die = die_type.get_die()
		DiceRoller.roll_die(die)
		dice.append(die)
	return dice
