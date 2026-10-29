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

func load_page() -> AdventurePage: return load(_leads_to)

func get_adventure_page() -> AdventurePage:
	# The adventure editor reads links too; Files isn't @tool
	var adventure_page: AdventurePage = load(_leads_to) if Engine.is_editor_hint() else Files.load_async(_leads_to)
	return adventure_page
