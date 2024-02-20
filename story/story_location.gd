class_name StoryLocation
extends Resource

@export_placeholder("Name") var name: String
@export var background: Texture
@export var ambience: AudioStream
@export var transitionss: Array[StoryDecision]

func enter() -> void:
	Stage.location = self
