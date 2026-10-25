@tool
class_name AdventureTransition
extends AdventurePageReference

@export_file("*.tres") var _leads_to: String

func prepare() -> void:
	ResourceLoader.load_threaded_request(_leads_to)

func get_adventure_page() -> AdventurePage:
	# The adventure editor reads links too; Files isn't @tool
	var adventure_page: AdventurePage = load(_leads_to) if Engine.is_editor_hint() else Files.load_async(_leads_to)
	return adventure_page
