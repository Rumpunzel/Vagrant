@tool
class_name AdventureFightDecision
extends AdventureDiceDecision

## The encounter whose monster fights, by UID; empty: the encounter of the event it is in
@export_file("*.tres") var encounter: String
## A one-off fight, when there is no monster encounter: the first fights, fresh at each location
@export var enemies: Array[MonsterProfile]
@export var stance_descriptions: Dictionary[CharacterAttribute, String] = {}
@export_multiline var flee_description: String = "Flee!"
@export var flee_transition: AdventurePageReference
@export var draw_transition: AdventurePageReference

## The encounter whose monster fights: the named one, else [param own] (the encounter of the event it is in); none if that has no monster
func get_monster_encounter(own: AdventureEncounter) -> AdventureEncounter:
	var fought: AdventureEncounter = Files.load_existing(encounter) as AdventureEncounter if not encounter.is_empty() else own
	return fought if fought != null and fought.profile is MonsterProfile else null

## Who fights: the monster of [method get_monster_encounter], else the first of [member enemies] (a one-off fight); the story and the
## adventure editor both go by this
func get_monster_profile(own: AdventureEncounter) -> MonsterProfile:
	var fought: AdventureEncounter = get_monster_encounter(own)
	if fought != null: return fought.profile as MonsterProfile
	return enemies[0] if not enemies.is_empty() else null

## Won, Lost, Fled, Draw; fleeing and a draw do nothing but lead on
func get_outcomes() -> Array[Outcome]:
	return [
		Outcome.new("Won", &"transition", &"consequences"),
		Outcome.new("Lost", &"failure_transition", &"failure_consequences"),
		Outcome.new("Fled", &"flee_transition", &""),
		Outcome.new("Draw", &"draw_transition", &""),
	]

## The outcome a fight that ended so takes
func get_fight_outcome(fight_outcome: Fight.Outcome) -> Outcome:
	assert(fight_outcome != Fight.Outcome.ONGOING, "Fight is still ongoing")
	var outcomes: Array[Outcome] = get_outcomes()
	match fight_outcome:
		Fight.Outcome.WON: return outcomes[0]
		Fight.Outcome.LOST: return outcomes[1]
		Fight.Outcome.FLED: return outcomes[2]
	return outcomes[3]

func to_dice_request(protagonist: Character) -> FightRequest:
	return FightRequest.new(protagonist, self)
