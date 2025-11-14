class_name StoryFightDecision
extends StoryDecision

@export var enemies: Array[MonsterProfile]
@export var stance_descriptions: Dictionary[CharacterAttribute, String] = {}
@export var failure_transition: StoryPageReference

func to_fight_request(protagonist: Character) -> FightRequest:
	return FightRequest.new(protagonist, self)
