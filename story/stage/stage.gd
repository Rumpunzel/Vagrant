@tool
class_name Stage
extends CanvasLayer

@export_group("Configuration")
@export var _ambience: AudioStreamPlayer
@export var _background: PackedScene

var _current_background: TextureRect

var location: StoryLocation :
	set(new_location):
		if location == new_location: return
		location = new_location
		_ambience.stream = location.ambience
		if not Engine.is_editor_hint() and is_inside_tree(): _ambience.play()
		var new_background: TextureRect = _background.instantiate()
		if _current_background:
			_current_background.add_sibling(new_background)
		else:
			_ambience.add_sibling(new_background)
		new_background.texture = location.background
		if _current_background != null:
			var tween := create_tween()
			tween.tween_property(new_background, "modulate:a", 1.0, 2.0).from(0.0)
			await tween.finished
			remove_child(_current_background)
			_current_background.queue_free()
		_current_background = new_background
