@tool
class_name StoryPage
extends Resource

@export_multiline var description: String : get = _get_description
@export var thumbnail: Texture : get = _get_thumbnail
@export var decisions: Array[StoryDecision] : get = _get_decisions

func _get_description() -> String:
	return description

func _get_thumbnail() -> Texture:
	return thumbnail

func _get_decisions() ->  Array[StoryDecision]:
	return decisions
