class_name Game
extends Node

@export var default_adventure: Adventure

func _ready() -> void:
	await get_tree().process_frame
	default_adventure.start_adventure()
