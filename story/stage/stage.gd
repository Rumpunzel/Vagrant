@tool
class_name Stage
extends CanvasLayer

@export_group("Configuration")
@export var _background: TextureRect
@export var _ambience: AudioStreamPlayer

var location: StoryLocation :
	set(new_location):
		if location == new_location: return
		location = new_location
		_background.texture = location.background
		_ambience.stream = location.ambience
		if not Engine.is_editor_hint() and is_inside_tree(): _ambience.play()
