@abstract
class_name AdventureDiceDecision
extends AdventureDecision

@export var failure_transition: AdventurePageReference
@export var failure_consequences: Array[AdventureConsequence]

@abstract func to_dice_request(protagonist: Character) -> DiceRequest
