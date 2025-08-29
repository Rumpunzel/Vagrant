class_name StorySaveDecision
extends StoryDecision

@export var attribute: CharacterAttribute
@export_range(0, 12) var difficulty: int
@export_multiline var details: String
@export var failure_transition: StoryPageReference

func to_save_request(protagonist: Character) -> SaveRequest:
	return SaveRequest.new(protagonist, attribute, difficulty, details)

func to_dialog_button_text() -> String:
	return "[color=#%s][%s][/color] %s" % [attribute.color.to_html(), attribute, super.to_dialog_button_text()]
