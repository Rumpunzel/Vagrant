class_name AdventurePlayFrom
extends RefCounted

## "Play from here" in the adventure editor: it writes where to start, the game (a debug run) takes it once on starting.

const PATH: String = "user://adventure_editor_play_from.cfg"

var adventure: Adventure
var page: AdventurePage
## The page [member page]'s event is on, or none
var host: AdventurePage
## The event played from: shown on the first arrival whatever its conditions, or none
var forced: AdventureEvent

## [param start]: where to start; [param start_host]: the page its event is on (for pages behind an event), or none
static func write(to_play: Adventure, start: AdventurePage, start_host: AdventurePage, start_forced: AdventureEvent = null) -> void:
	var file: ConfigFile = ConfigFile.new()
	file.set_value("start", "adventure", to_play.resource_path)
	file.set_value("start", "page", _locate(start))
	file.set_value("start", "host", _locate(start_host) if start_host != null else [ ])
	file.set_value("start", "forced", _locate(start_forced) if start_forced != null else [ ])
	file.save(PATH)

## Where to start, and the file is gone; none if there was none
static func take() -> AdventurePlayFrom:
	if not FileAccess.file_exists(PATH): return null
	var file: ConfigFile = ConfigFile.new()
	file.load(PATH)
	DirAccess.remove_absolute(PATH)
	var start: AdventurePlayFrom = AdventurePlayFrom.new()
	var adventure_path: String = file.get_value("start", "adventure")
	var page_location: Array = file.get_value("start", "page")
	start.adventure = load(adventure_path) as Adventure
	start.page = _find(page_location)
	if start.adventure == null or start.page == null: return null
	var host_location: Array = file.get_value("start", "host")
	start.host = _find(host_location) if not host_location.is_empty() else null
	var forced_location: Array = file.get_value("start", "forced", [ ])
	start.forced = _find(forced_location) as AdventureEvent if not forced_location.is_empty() else null
	return start

## [its file, its ID in there (empty: the file itself)]: pages stored inside a file have no path of their own to load
static func _locate(located: AdventurePage) -> Array:
	var file: String = located.resource_path.get_slice("::", 0)
	return [file, located.resource_scene_unique_id if located.resource_path.contains("::") else ""]

static func _find(location: Array) -> AdventurePage:
	var file: String = location[0]
	var root: AdventurePage = load(file) as AdventurePage
	var id: String = location[1]
	if root == null or id.is_empty(): return root
	for held: AdventurePage in root.get_held_pages(): if held.resource_scene_unique_id == id: return held
	return null
