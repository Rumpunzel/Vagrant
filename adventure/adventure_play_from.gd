class_name AdventurePlayFrom
extends RefCounted

## "Play from here" in the adventure editor: it writes where to start, the game (a debug run) takes it once on starting.

const PATH: String = "user://adventure_editor_play_from.cfg"

## [param page]: where to start; [param host]: the page its event is on (for pages behind an event), or none
static func write(adventure: Adventure, page: AdventurePage, host: AdventurePage) -> void:
	var start: ConfigFile = ConfigFile.new()
	start.set_value("start", "adventure", adventure.resource_path)
	start.set_value("start", "page", _locate(page))
	start.set_value("start", "host", _locate(host) if host != null else [ ])
	start.save(PATH)

## [adventure, page, host] and the file is gone; empty if there was none
static func take() -> Array:
	if not FileAccess.file_exists(PATH): return [ ]
	var start: ConfigFile = ConfigFile.new()
	start.load(PATH)
	DirAccess.remove_absolute(PATH)
	var adventure: Adventure = load(start.get_value("start", "adventure")) as Adventure
	var page: AdventurePage = _find(start.get_value("start", "page"))
	if adventure == null or page == null: return [ ]
	var host: Array = start.get_value("start", "host")
	return [adventure, page, _find(host) if not host.is_empty() else null]

## [its file, its ID in there (empty: the file itself)]: pages stored inside a file have no path of their own to load
static func _locate(page: AdventurePage) -> Array:
	var file: String = page.resource_path.get_slice("::", 0)
	return [file, page.resource_scene_unique_id if page.resource_path.contains("::") else ""]

static func _find(location: Array) -> AdventurePage:
	var root: AdventurePage = load(location[0]) as AdventurePage
	if root == null or location[1].is_empty(): return root
	for page: AdventurePage in root.get_held_pages(): if page.resource_scene_unique_id == location[1]: return page
	return null
