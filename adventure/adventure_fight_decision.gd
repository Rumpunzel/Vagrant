class_name AdventureFightDecision
extends AdventureDiceDecision

@export var enemies: Array[MonsterProfile]
@export var stance_descriptions: Dictionary[CharacterAttribute, String] = {}
@export var failure_transition: AdventurePageReference

func to_dice_request(protagonist: Character) -> FightRequest:
	return FightRequest.new(protagonist, self)
