class_name StorySaveDecision
extends StoryDecision

@export_multiline var details: String
@export var attribute: CharacterAttribute
@export_range(0, 12) var difficulty: int
@export var failure_transition: StoryPageReference

func to_save_request(protagonist: Character) -> SaveRequest:
	return SaveRequest.new(protagonist, attribute, self)
