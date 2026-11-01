@tool
class_name AdventureTransition
extends AdventurePageReference

@export_file("*.tres") var _leads_to: String

## A transition to [param page] by its UID (by its path if it has none)
static func leading_to(page: AdventurePage) -> AdventureTransition:
	var transition: AdventureTransition = AdventureTransition.new()
	var uid: int = ResourceLoader.get_resource_uid(page.resource_path)
	transition._leads_to = ResourceUID.id_to_text(uid) if uid != ResourceUID.INVALID_ID else page.resource_path
	return transition

func prepare() -> void:
	ResourceLoader.load_threaded_request(_leads_to)

## Its file is gone (or none was set)
func leads_nowhere() -> bool: return not ResourceLoader.exists(_leads_to)

func load_page() -> AdventurePage: return load(_leads_to)

## Without loading it: a visited page stays loaded (the story's page log holds it), one not loaded yet wasn't visited
func was_visited(story: Story) -> bool:
	var path: String = ResourceUID.uid_to_path(_leads_to) if _leads_to.begins_with("uid://") else _leads_to
	var page: AdventurePage = ResourceLoader.get_cached_ref(path) as AdventurePage
	return page != null and story.get_how_often_page_has_been_entered(page) > 0

func get_adventure_page() -> AdventurePage:
	# The adventure editor reads links too; Files isn't @tool
	if Engine.is_editor_hint(): return load_page()
	var adventure_page: AdventurePage = Files.load_async(_leads_to)
	return adventure_page
