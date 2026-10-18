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
var weapon_damage: int = 0
var injury_taken: int = 0

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

func get_score(attribute: CharacterAttribute) -> int:
	return scores[attribute] - impairments.get(attribute, 0)

func is_armed() -> bool: return not weapon_dice.is_empty()
