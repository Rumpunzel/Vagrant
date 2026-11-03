class_name SaveGame
extends RefCounted

## One run's save, a slot per run that is autosaved: JSON in [constant DIRECTORY]. Names content by [ResourceId]; a save from another
## format version, or naming something that is gone (the adventure changed), can't be loaded.

const VERSION: int = 1
const DIRECTORY: String = "user://saves"

## The run's slot: its file name without extension
var run: String
## [method Story.get_save]
var story: Dictionary = {}
var saved_at: String

static func start_run() -> String: return Time.get_datetime_string_from_system().replace(":", "-")

static func get_path_of(of_run: String) -> String: return DIRECTORY.path_join(of_run + ".json")

## The saved runs, oldest first (their names are their start times)
static func get_runs() -> Array[String]:
	var runs: Array[String] = []
	for file: String in DirAccess.get_files_at(DIRECTORY): if file.get_extension() == "json": runs.append(file.get_basename())
	runs.sort()
	return runs

static func capture(of_run: String, from_story: Story) -> SaveGame:
	var save_game: SaveGame = SaveGame.new()
	save_game.run = of_run
	save_game.story = from_story.get_save()
	save_game.saved_at = Time.get_datetime_string_from_system()
	return save_game

func write() -> Error:
	DirAccess.make_dir_recursive_absolute(DIRECTORY)
	var file: FileAccess = FileAccess.open(get_path_of(run), FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify({version = VERSION, saved_at = saved_at, story = story}, "\t"))
	return OK

## Null if there is no such save, or it can't be read
static func read(of_run: String) -> SaveGame:
	var text: String = FileAccess.get_file_as_string(get_path_of(of_run))
	var parsed: Variant = JSON.parse_string(text) if not text.is_empty() else null
	if not parsed is Dictionary: return null
	var data: Dictionary = parsed
	var save_game: SaveGame = SaveGame.new()
	save_game.run = of_run
	save_game.saved_at = data.get("saved_at", "")
	save_game.story = data.get("story", {})
	if int(data.get("version", 0)) != VERSION: save_game.story = {}
	return save_game

## Why it can't be loaded (each ID that is gone), or nothing
func get_problems() -> Array[String]:
	if story.is_empty(): return ["Saved by another version of the game."] as Array[String]
	var problems: Array[String] = []
	for id: String in _find_ids(story):
		var problem: String = "Gone from the adventure: %s" % id
		if not problems.has(problem) and ResourceId.find(id) == null: problems.append(problem)
	return problems

## Every [ResourceId] in [param value]: strings that name a file
static func _find_ids(value: Variant) -> Array[String]:
	var ids: Array[String] = []
	if value is String:
		var text: String = value
		if text.begins_with("uid://") or text.begins_with("res://") or text.begins_with("user://"): ids.append(text)
	elif value is Array:
		for item: Variant in value as Array: ids.append_array(_find_ids(item))
	elif value is Dictionary:
		var dictionary: Dictionary = value
		for key: Variant in dictionary:
			ids.append_array(_find_ids(key))
			ids.append_array(_find_ids(dictionary[key]))
	return ids
