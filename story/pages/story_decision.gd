@tool
class_name StoryDecision
extends Resource

@export var description: String
@export var transition: StoryTransition

static func get_continue() -> StoryDecision:
	var continue_decision := StoryDecision.new()
	continue_decision.description = "Continue"
	continue_decision.transition = StoryTransition.new()
	return continue_decision

func to_dialog_button_text() -> String:
	return description
