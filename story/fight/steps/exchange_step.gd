@abstract
class_name ExchangeStep
extends Resource

## One step of an exchange, for one side. [ExchangeSteps] puts them in order: the resolution steps as authored, the others as the rules fix them.
## Steps are shared resources: everything they work on comes from the [Fight] passed in.

enum ExchangeSide {
	## The protagonist in the story
	FIRST,
	SECOND,
}

@export var side: ExchangeSide = ExchangeSide.FIRST

## Applies this part of the exchange and returns what to tell about it
@abstract func enter(fight: Fight) -> String
## Checked once the step before it was entered; steps that don't apply are skipped
func applies(_fight: Fight) -> bool: return true

func is_first() -> bool: return side == ExchangeSide.FIRST
## This step's side is the player's: their choices are asked for, and the texts speak to them
func is_player(fight: Fight) -> bool: return get_actor(fight) == fight.player
func get_side(fight: Fight) -> FightSide: return fight.get_last_exchange().first if is_first() else fight.get_last_exchange().second
func get_foe_side(fight: Fight) -> FightSide: return fight.get_last_exchange().second if is_first() else fight.get_last_exchange().first
## The character or monster this step is for
func get_actor(fight: Fight) -> Actor: return fight.first if is_first() else fight.second
func get_foe(fight: Fight) -> Actor: return fight.second if is_first() else fight.first
## "You" / "The Lurker" / "Dorian"
func get_subject(fight: Fight) -> String: return Fight.capitalize_first(Fight.describe_actor(get_actor(fight), fight.player))
func get_foe_subject(fight: Fight) -> String: return Fight.capitalize_first(Fight.describe_actor(get_foe(fight), fight.player))
## "you" / "the Lurker" / "Dorian", as the object of a sentence
func get_object(fight: Fight) -> String: return Fight.describe_actor(get_actor(fight), fight.player)
## "your" / "the Lurker's" / "Dorian's"
func get_owner(fight: Fight) -> String: return "your" if is_player(fight) else get_actor(fight).get_reference() + "'s"
func get_foe_owner(fight: Fight) -> String: return "your" if get_foe(fight) == fight.player else get_foe(fight).get_reference() + "'s"
## "your" / "its" / "their"
func get_pronoun(fight: Fight) -> String: return "your" if is_player(fight) else get_actor(fight).get_possessive_pronoun()
func get_weapon(fight: Fight) -> Weapon: return get_side(fight).weapon
func get_foe_weapon(fight: Fight) -> Weapon: return get_foe_side(fight).weapon
func get_shield(fight: Fight) -> Shield: return get_side(fight).shield
## [param player_text] if this step's side is the player's, else [param other_text]: "press" / "presses"
func pick(fight: Fight, player_text: String, other_text: String) -> String: return player_text if is_player(fight) else other_text
## The same for the foe's verbs
func pick_foe(fight: Fight, player_text: String, other_text: String) -> String: return player_text if get_foe(fight) == fight.player else other_text

## "Veteran turns your vantage of 3 into 6." when an origin's ability changed this side's vantage (the foe's with [param of_foe]), else ""
func describe_vantage_ability(fight: Fight, of_foe: bool = false) -> String:
	var vantage_side: FightSide = get_foe_side(fight) if of_foe else get_side(fight)
	if vantage_side.vantage == vantage_side.base_vantage: return ""
	var actor: Actor = get_foe(fight) if of_foe else get_actor(fight)
	var pronoun: String = "your" if actor == fight.player else actor.get_possessive_pronoun()
	var base: int = vantage_side.base_vantage
	var origins: Array[String] = actor.get_origin_names(func(ability: Ability) -> bool: return ability.modify_vantage(base) != base)
	return "%s %s %s vantage of %d into %d." % [" and ".join(origins), "turn" if origins.size() > 1 else "turns", pronoun, base, vantage_side.vantage]

## Marks [param face] on [param equipment] and returns the line telling it, "" if nothing was marked
static func _mark(equipment: Equipment, face: int, owner: String) -> String:
	if not equipment or not equipment.is_usable(): return ""
	var marked: int = equipment.mark(face)
	if marked == 0: return "%s %s is ruined." % [owner.capitalize(), equipment.get_equipment_name()]
	return "A %d is marked on %s %s." % [marked, owner, equipment.get_equipment_name()]

static func _join(lines: Array[String]) -> String:
	return " ".join(lines.filter(func(line: String) -> bool: return not line.is_empty()))
