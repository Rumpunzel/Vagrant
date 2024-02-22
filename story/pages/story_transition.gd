class_name StoryTransition
extends StoryPageReference

@export_file("*.tres") var _leads_to: String

func get_story_page() -> StoryPage:
	return load(_leads_to)
