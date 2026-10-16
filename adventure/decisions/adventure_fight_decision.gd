class_name AdventureFightDecision
extends AdventureDiceDecision

@export var enemies: Array[MonsterProfile]
@export var stance_descriptions: Dictionary[CharacterAttribute, String] = {}
@export_multiline var flee_description: String = "Flee!"
@export var flee_transition: AdventurePageReference
@export var draw_transition: AdventurePageReference

func to_dice_request(protagonist: Character) -> FightRequest:
	return FightRequest.new(protagonist, self)
