class_name Game
extends Node

@export var default_adventure: Adventure

func _ready() -> void:
	await get_tree().process_frame
	# The adventure editor's "Play from here"
	var start: Array = AdventurePlayFrom.take() if OS.is_debug_build() else [ ]
	if not start.is_empty(): (start[0] as Adventure).start_adventure(start[1], start[2])
	else: default_adventure.start_adventure()
