extends Node

## Runs the Fight Lab in its own headless Godot process, so the game's autoloads are there and the editor stays responsive:
## [code]godot --headless --path <project> <this scene> -- --settings=<FightLabRunSettings path> --out=<json path>[/code]
## Writes "done/total" to [code]<json path>.progress[/code] as it goes, then the result as JSON.

func _ready() -> void:
	var arguments: Dictionary[String, String] = {}
	for argument: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = argument.trim_prefix("--").split("=", true, 1)
		if parts.size() == 2: arguments[parts[0]] = parts[1]
	var settings: FightLabRunSettings = load(arguments.get("settings", "")) as FightLabRunSettings
	var out: String = arguments.get("out", "")
	if not settings or not settings.scenario or out.is_empty():
		push_error("Fight Lab: needs --settings=<FightLabRunSettings with a scenario> and --out=<file>")
		get_tree().quit(1)
		return
	var run: FightLabRun = FightLabRun.new(settings)
	run.progressed.connect(func(done: int, total: int) -> void: _write(out + ".progress", "%d/%d" % [done, total]))
	_write(out, JSON.stringify(run.execute(self)))
	get_tree().quit()

static func _write(path: String, text: String) -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()
