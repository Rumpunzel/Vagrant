class_name StoryLocation
extends Resource

@export_placeholder("Name") var name := ""
@export var background: Texture
@export var ambience: AudioStream

func enter() -> void:
	Stage.location = self
