class_name Game
extends Node

@export var default_adventure: Adventure

func _ready() -> void:
	await get_tree().process_frame
	# The adventure editor's "Play from here"
	var start: AdventurePlayFrom = AdventurePlayFrom.take() if OS.is_debug_build() else null
	if start != null: start.adventure.start_adventure(start.page, start.host)
	else: default_adventure.start_adventure()
