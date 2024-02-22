@tool
class_name StoryPage
extends StoryPageReference

@export_multiline var _description: String
@export var _thumbnail: Texture
@export var _decisions: Array[StoryDecision]

func get_description() -> String:
	return "[p]%s[/p]" % _description

func get_thumbnail() -> Texture:
	return _thumbnail

func get_decisions() ->  Array[StoryDecision]:
	return _decisions

func get_story_page() -> StoryPage:
	return self
