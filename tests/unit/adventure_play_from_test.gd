extends GdUnitTestSuite

## "Play from here": the start the editor writes is the one the game takes, once; pages stored inside a file are found by their ID there.

const EVENT_PATH: String = "user://play_from_test_event.tres"
const ADVENTURE_PATH: String = "user://play_from_test_adventure.tres"

var _adventure: Adventure
var _event: AdventurePage
var _inside: AdventurePage
var _host: AdventurePage

func before_test() -> void:
	_inside = AdventurePage.new()
	_inside.title = "Inside"
	var decision: AdventureDecision = AdventureDecision.new()
	decision.transition = _inside
	_event = AdventurePage.new()
	_event.title = "Ambush"
	_event.decisions = [decision] as Array[AdventureDecision]
	ResourceSaver.save(_event, EVENT_PATH)
	_event = ResourceLoader.load(EVENT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)
	_inside = _event.decisions[0].transition
	_host = _event
	_adventure = Adventure.new()
	_adventure.starting_page = _event
	ResourceSaver.save(_adventure, ADVENTURE_PATH)
	_adventure = ResourceLoader.load(ADVENTURE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE)

func after_test() -> void:
	for path: String in [EVENT_PATH, ADVENTURE_PATH, AdventurePlayFrom.PATH]: if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func test_takes_what_was_written_once() -> void:
	AdventurePlayFrom.write(_adventure, _inside, _host)
	var start: Array = AdventurePlayFrom.take()
	assert_str((start[0] as Adventure).resource_path).is_equal(ADVENTURE_PATH)
	assert_str((start[1] as AdventurePage).title).is_equal("Inside")
	assert_str((start[2] as AdventurePage).title).is_equal("Ambush")
	assert_array(AdventurePlayFrom.take()).is_empty()

func test_no_host() -> void:
	AdventurePlayFrom.write(_adventure, _event, null)
	var start: Array = AdventurePlayFrom.take()
	assert_str((start[1] as AdventurePage).title).is_equal("Ambush")
	assert_object(start[2]).is_null()

func test_nothing_written() -> void:
	assert_array(AdventurePlayFrom.take()).is_empty()

func test_held_pages() -> void:
	var nested: AdventurePage = AdventurePage.new()
	var nearby: AdventurePage = AdventurePage.new()
	_inside.events = [nested] as Array[AdventurePage]
	_inside.nearby_events = [nearby] as Array[AdventurePage]
	var other_file: AdventureDecision = AdventureDecision.new()
	other_file.transition = AdventureTransition.new()
	_inside.decisions = [other_file] as Array[AdventureDecision]
	assert_array(_event.get_held_pages()).contains_exactly([_event, _inside, nested, nearby])
