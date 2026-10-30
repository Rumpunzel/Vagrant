@tool
class_name AdventureFightDecision
extends AdventureDiceDecision

@export var enemies: Array[MonsterProfile]
@export var stance_descriptions: Dictionary[CharacterAttribute, String] = {}
@export_multiline var flee_description: String = "Flee!"
@export var flee_transition: AdventurePageReference
@export var draw_transition: AdventurePageReference

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
