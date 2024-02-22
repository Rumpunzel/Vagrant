@tool
class_name StoryDecision
extends Resource

@export var description: String
@export var transition: StoryPageReference

static func get_continue() -> StoryDecision:
	var continue_decision := StoryDecision.new()
	continue_decision.description = "Continue."
	continue_decision.transition = StoryPageReference.new()
	return continue_decision

func to_dialog_button_text() -> String:
	return description
