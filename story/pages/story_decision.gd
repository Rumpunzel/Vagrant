class_name StoryDecision
extends Resource

@export_multiline var description: String
@export var transition: StoryPageReference

static func get_continue() -> StoryDecision:
	return preload("res://story/pages/continue.tres")

func to_dialog_button_text() -> String:
	return description
