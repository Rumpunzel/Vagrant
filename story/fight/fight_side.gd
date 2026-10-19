class_name FightSide
extends RefCounted

## One side of a single exchange: what it chose and rolled going in, and what happened to it.
## Filled in by [FightExchange]; contains no randomness itself.

# Input
## Set by [FightExchange]: Blood when fleeing, Guts when unarmed
var stance: CharacterAttribute
var fleeing: bool
var breath_dice: Array[Die]
var weapon_dice: Array[Die]
## Attribute the weapon is wielded with; null = Guts
var wield_attribute: CharacterAttribute
## Faces of the weapon die that are marked and deal no damage
var marked_faces: Array[int] = []
## Claws, fangs and the like: the breath dice are the weapon dice and need no wield check
var has_natural_weapons: bool = false
## Shield die rolled this exchange (none without a shield)
var shield_dice: Array[Die] = []
## Attribute the shield is raised with; null = Guts
var shield_wield_attribute: CharacterAttribute
var shield_marked_faces: Array[int] = []
## Weapon die results this side's armour blocks
var armor_blocks: Array[int] = []
## Subtracted from all damage this side takes
var damage_reduction: int = 0
## Effective attribute scores at the start of the exchange (injuries already applied)
var scores: Dictionary[CharacterAttribute, int]
## Foe attribute to impair when threatening with Nerves
var nerves_target: CharacterAttribute

# Result
var threat: int = 0
## Attribute -> reduction inflicted by the foe's Nerves for this exchange
var impairments: Dictionary[CharacterAttribute, int] = {}
var lost_breath_dice: Array[Die] = []
var usable_weapon_dice: Array[Die] = []
## Weapon dice rolled above the wield score: the weapon could not be wielded, and these faces get marked
var failed_weapon_dice: Array[Die] = []
## Wielded weapon dice the foe's armour blocked: they deal no damage
var blocked_weapon_dice: Array[Die] = []
## Shield dice rolled above the wield score: the shield could not be raised, and these faces get marked
var failed_shield_dice: Array[Die] = []
## The foe die this side's shield lowered, and by how much
var shield_target: Die
var shield_value: int = 0
## Rolled results the foe's shield lowered: Die -> result used for threat and damage
var reduced_results: Dictionary[Die, int] = {}
var weapon_damage: int = 0
var injury_taken: int = 0
## How much of the foe's blow this side's armour took off
var damage_prevented: int = 0

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

func get_fight_stance() -> FightStance:
	var fight_stance: FightStance = stance.fight_stance
	assert(fight_stance, "%s has no FightStance" % stance)
	return fight_stance

## The result a die counts with: lowered by the foe's shield, otherwise as rolled
func get_result(die: Die) -> int: return reduced_results.get(die, die.result)

func get_score(attribute: CharacterAttribute) -> int:
	return scores[attribute] - impairments.get(attribute, 0)

func is_armed() -> bool: return not weapon_dice.is_empty()
