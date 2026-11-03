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
	file.set_value("start", "adventure", ResourceId.of(to_play))
	file.set_value("start", "page", ResourceId.of(start))
	file.set_value("start", "host", ResourceId.of(start_host))
	file.set_value("start", "forced", ResourceId.of(start_forced))
	file.save(PATH)

## Where to start, and the file is gone; none if there was none
static func take() -> AdventurePlayFrom:
	if not FileAccess.file_exists(PATH): return null
	var file: ConfigFile = ConfigFile.new()
	file.load(PATH)
	DirAccess.remove_absolute(PATH)
	var start: AdventurePlayFrom = AdventurePlayFrom.new()
	start.adventure = ResourceId.find(file.get_value("start", "adventure", "") as String) as Adventure
	start.page = ResourceId.find(file.get_value("start", "page", "") as String) as AdventurePage
	if start.adventure == null or start.page == null: return null
	start.host = ResourceId.find(file.get_value("start", "host", "") as String) as AdventurePage
	start.forced = ResourceId.find(file.get_value("start", "forced", "") as String) as AdventureEvent
	return start
