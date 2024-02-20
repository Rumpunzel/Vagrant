class_name StorySaveDecision
extends StoryDecision

@export var attribute: CharacterAttribute
@export_range(0, 12) var difficulty: int
@export_multiline var details: String
@export var failure_transition: StoryTransition

func to_save_request() -> SaveRequest:
	var protagonist: Character = Characters.get_protagonist()
	return SaveRequest.new(protagonist, attribute, difficulty, details)

func to_dialog_button_text() -> String:
	return "[color=#%s][%s][/color] %s" % [attribute.color.to_html(), attribute, super.to_dialog_button_text()]
