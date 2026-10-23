class_name FightSide
extends RefCounted

## One side of a single exchange: what it chose and rolled going in, and what happened to it.
## Filled in by [FightExchange]; contains no randomness itself.

enum ShieldUse {
	## As the side's [ShieldTactic] decides
	AUTO,
	## Raised even if it has to be forced
	RAISE,
	LOWER,
}

enum Strain {
	NONE,
	## Forced on a marked face within the wield score: the next higher face gets marked
	MARKED_FACE,
	## Forced above the wield score: one face gets marked per point it is above
	OVERREACH,
}

# Input
## Set by [FightExchange]: Blood when fleeing, Guts when unarmed
var stance: CharacterAttribute
var fleeing: bool
var breath_dice: Array[Die]
var weapon_dice: Array[Die]
## Attribute the weapon is wielded with; null = Guts
var wield_attribute: CharacterAttribute
## Faces of the weapon die that are marked: they can only be used by forcing the weapon
var marked_faces: Array[int] = []
## The weapon die chosen to strike with, forced if need be; null: as the [member weapon_tactic] decides
var chosen_weapon_die: Die
## Strike with none of the weapon dice
var holds_back: bool = false
## Claws, fangs and the like: the breath dice are the weapon dice and need no wield check
var has_natural_weapons: bool = false
## At most one die, rolled with the others
var shield_dice: Array[Die] = []
## Attribute the shield is raised with; null = Guts
var shield_wield_attribute: CharacterAttribute
var shield_marked_faces: Array[int] = []
var shield_use: ShieldUse = ShieldUse.AUTO
var armor_blocks: Array[int] = []
var damage_reduction: int = 0
## Effective attribute scores at the start of the exchange (injuries already applied)
var scores: Dictionary[CharacterAttribute, int]
## Foe attribute to impair when threatening with Nerves
var nerves_target: CharacterAttribute
## The fighter's abilities (monsters have none yet)
var abilities: Array[Ability] = []
## How this side commits when nobody asks the player; none: never forcing, sparing armour
var weapon_tactic: WeaponTactic
var shield_tactic: ShieldTactic
var armor_tactic: ArmorTactic

# Result
var threat: int = 0
## Attribute -> reduction inflicted by the foe's Nerves for this exchange
var impairments: Dictionary[CharacterAttribute, int] = {}
var lost_breath_dice: Array[Die] = []
## The weapon die struck with (at most one)
var usable_weapon_dice: Array[Die] = []
## How striking with it strains the weapon
var weapon_strain: Strain = Strain.NONE
## How far the weapon die struck with is above the wield score; taken off the threat
var weapon_overshoot: int = 0
## The foe's Nerves made this side drop its weapon, or its shield, for the rest of the fight
var weapon_dropped: bool = false
var shield_dropped: bool = false
## Weapon dice that could be used freely but were not chosen
var spare_weapon_dice: Array[Die] = []
## Weapon dice that would have needed forcing (above the wield score or on a marked face) and were not used
var failed_weapon_dice: Array[Die] = []
## Wielded weapon dice the foe's armour blocked: they deal no damage
var blocked_weapon_dice: Array[Die] = []
## The foe's blow before this side's shield (after both stances)
var blow: int = 0
var raises_shield: bool = false
## How far the raised shield's die is above its wield score; taken off the threat
var shield_overshoot: int = 0
## What the raised shield took off the blow, at most all of it
var shield_blocked: int = 0
var weapon_damage: int = 0
var injury_taken: int = 0
## How much of the foe's blow this side's armour took off
var damage_prevented: int = 0
## What this side's stance did with its vantage to the damage: added to its own blow (Guts), taken off the foe's (Blood)
var damage_added: int = 0
var damage_avoided: int = 0

func _init(
	with_stance: CharacterAttribute,
	with_breath_dice: Array[Die],
	with_scores: Dictionary[CharacterAttribute, int],
	with_weapon_dice: Array[Die] = [],
	is_fleeing: bool = false,
	with_nerves_target: CharacterAttribute = null,
) -> void:
	stance = with_stance
	breath_dice = with_breath_dice
	scores = with_scores
	weapon_dice = with_weapon_dice
	fleeing = is_fleeing
	nerves_target = with_nerves_target

func get_wield_score() -> int: return get_score(wield_attribute if wield_attribute else Rules.STRENGTH)

func get_shield_wield_score() -> int: return get_score(shield_wield_attribute if shield_wield_attribute else Rules.STRENGTH)

func get_weapon_overshoot(die: Die) -> int: return maxi(die.result - get_wield_score(), 0)

func get_shield_overshoot() -> int: return maxi(shield_dice[0].result - get_shield_wield_score(), 0)

## Can be struck with without forcing the weapon
func is_free_weapon_die(die: Die) -> bool: return die.result <= get_wield_score() and not marked_faces.has(die.result)

## A fresh side with the same inputs, to resolve the exchange again (e.g. after choosing a weapon die)
func copy_inputs() -> FightSide:
	var copy: FightSide = FightSide.new(stance, breath_dice, scores, weapon_dice, fleeing, nerves_target)
	copy.wield_attribute = wield_attribute
	copy.marked_faces = marked_faces
	copy.chosen_weapon_die = chosen_weapon_die
	copy.holds_back = holds_back
	copy.has_natural_weapons = has_natural_weapons
	copy.shield_dice = shield_dice
	copy.shield_wield_attribute = shield_wield_attribute
	copy.shield_marked_faces = shield_marked_faces
	copy.shield_use = shield_use
	copy.armor_blocks = armor_blocks
	copy.damage_reduction = damage_reduction
	copy.abilities = abilities
	copy.weapon_tactic = weapon_tactic
	copy.shield_tactic = shield_tactic
	copy.armor_tactic = armor_tactic
	return copy

func get_fight_stance() -> FightStance:
	var fight_stance: FightStance = stance.fight_stance
	assert(fight_stance, "%s has no FightStance" % stance)
	return fight_stance

func get_score(attribute: CharacterAttribute) -> int:
	return scores[attribute] - impairments.get(attribute, 0)

func is_armed() -> bool: return not weapon_dice.is_empty()
