class_name StoryTransition
extends Resource

@export var _next_page: StoryPage
@export_file("*.tres") var _leads_to: String

func get_next_page() -> StoryPage:
	if not _leads_to.is_empty():
		if _next_page != null: print("_next_page: %s is discared in <%s>" % [_next_page.resource_path, resource_path])
		return load(_leads_to)
	return _next_page
