@tool
class_name AdventureTransition
extends AdventurePageReference

@export_file("*.tres") var _leads_to: String

func get_adventure_page() -> AdventurePage:
	return load(_leads_to)
