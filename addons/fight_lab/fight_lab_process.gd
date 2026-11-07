@tool
class_name FightLabProcess
extends Node

## Runs [FightLabRunSettings] in the runner's own headless Godot process ([code]fight_lab_runner.gd[/code]), so the game's autoloads are there
## and the editor stays responsive. The Fight Lab dock and the adventure editor's fight odds both start their runs here.

signal progressed(done: int, total: int)
## [param result] as [method FightLabRun.execute] returns it; empty if the run failed
signal finished(result: Dictionary)

## Handed to the child process on its command line, which takes no uid://
const RUNNER_SCENE: String = "res://addons/fight_lab/fight_lab_runner.tscn"

var _pid: int = -1
var _out: String = ""

func _init() -> void:
	set_process(false)

## Saves [param settings] to [param settings_file] for the child process, which writes its result to [param out]; false if Godot didn't start
func start(settings: FightLabRunSettings, settings_file: String, out: String) -> bool:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(settings_file).get_base_dir())
	ResourceSaver.save(settings, settings_file)
	for path: String in [out, out + ".progress", out + ".log"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var arguments: PackedStringArray = [
		"--headless", "--path", ProjectSettings.globalize_path("res://"), "--log-file", ProjectSettings.globalize_path(out + ".log"), RUNNER_SCENE,
		"--", "--settings=" + settings_file, "--out=" + out,
	]
	_pid = OS.create_process(OS.get_executable_path(), arguments)
	if _pid < 0: return false
	_out = out
	set_process(true)
	return true

func is_running() -> bool: return _pid >= 0

## The errors the last run's process logged (its first few), to tell why it failed
func get_errors() -> String:
	var log_file: String = _out + ".log"
	if not FileAccess.file_exists(log_file): return ""
	var errors: Array[String] = []
	for line: String in FileAccess.get_file_as_string(log_file).split("\n"):
		if line.contains("ERROR") and not line.contains("still in use at exit") and not line.contains("leaked at exit"): errors.append(line.strip_edges())
	return "\n".join(errors.slice(0, 5))

## A finished run's result in [param out]; empty if there is none
static func read_result(out: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(out)) if FileAccess.file_exists(out) else null
	if not parsed is Dictionary or not (parsed as Dictionary).has("side_a"): return {}
	return parsed

func _process(_delta: float) -> void:
	if FileAccess.file_exists(_out + ".progress"):
		var parts: PackedStringArray = FileAccess.get_file_as_string(_out + ".progress").split("/")
		if parts.size() == 2: progressed.emit(parts[0].to_int(), parts[1].to_int())
	if OS.is_process_running(_pid): return
	_pid = -1
	set_process(false)
	finished.emit(read_result(_out))
