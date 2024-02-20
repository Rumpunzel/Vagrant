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
		_ambience.play()
		Events.location_changed.emit(location)
