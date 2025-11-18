class_name AdventureFightDecision
extends AdventureDiceDecision

@export var enemies: Array[MonsterProfile]
@export var stance_descriptions: Dictionary[CharacterAttribute, String] = {}
@export var failure_transition: AdventurePageReference

func to_dice_request(protagonist: Character) -> FightRequest:
	return FightRequest.new(protagonist, self)

func get_icon() -> Texture2D:
	var custom_icon: Texture2D = super.get_icon()
	if custom_icon: return custom_icon
	return preload("uid://b1s6hs7g8cdui")
