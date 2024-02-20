@tool
class_name StoryEvent
extends StoryPage

@export var exclusive := false

@export var _placeholder := true

func are_all_prerequisites_fullfilled() -> bool:
	return _placeholder
