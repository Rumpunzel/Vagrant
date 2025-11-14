class_name StoryDecision
extends Resource

@export_multiline var description: String
@export var transition: StoryPageReference

static func get_continue() -> StoryDecision:
	return load("res://story/pages/continue.tres")
