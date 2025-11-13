class_name StorySaveDecision
extends StoryDecision

@export_multiline var details: String
@export var attribute: CharacterAttribute
@export_range(0, 12) var difficulty: int
@export var failure_transition: StoryPageReference

func to_save_request(protagonist: Character) -> SaveRequest:
	return SaveRequest.new(protagonist, attribute, self)

func to_dialog_button_text() -> String:
	return "%s %s" % [attribute.to_bbcode(), super.to_dialog_button_text()]
