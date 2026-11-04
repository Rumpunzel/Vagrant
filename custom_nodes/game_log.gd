class_name GameLog
extends RefCounted

## Debug log of what happens in the game, one line each: "12:03:04 story: …". Godot's own file logging writes it to disk
## (user://logs/godot*.log, the last few runs) among the engine's errors and warnings. Release builds don't log.

static func write(category: String, message: String) -> void:
	if not OS.is_debug_build(): return
	print("%s %s: %s" % [Time.get_time_string_from_system(), category, message])
