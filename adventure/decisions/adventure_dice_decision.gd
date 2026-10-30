@tool
@abstract
class_name AdventureDiceDecision
extends AdventureDecision

@export var failure_transition: AdventurePageReference
@export var failure_consequences: Array[AdventureConsequence]

@abstract func to_dice_request(protagonist: Character) -> DiceRequest

func get_outcomes() -> Array[Outcome]:
	return [Outcome.new("Success", &"transition", &"consequences"), Outcome.new("Failure", &"failure_transition", &"failure_consequences")]

func get_outcome(success: bool) -> Outcome: return get_outcomes()[0 if success else 1]
