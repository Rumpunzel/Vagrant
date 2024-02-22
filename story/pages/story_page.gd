@tool
class_name StoryPage
extends StoryPageReference

@export var exclusive := false

@export var _placeholder := true
@export_multiline var _description: String
@export var _background: Texture
@export var _decisions: Array[StoryDecision]

func are_all_prerequisites_fullfilled() -> bool:
	return _placeholder

func get_description() -> String:
	return "[p]%s[/p]" % _description

func get_background() -> Texture:
	return _background

func get_decisions() ->  Array[StoryDecision]:
	return _decisions

func get_story_page() -> StoryPage:
	return self
