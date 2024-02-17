extends Node

@export var starting_location: StoryLocation

func _ready() -> void:
	starting_location.enter()
