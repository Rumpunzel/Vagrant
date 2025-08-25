@tool
class_name Stage
extends CanvasLayer

@export var background: Texture : set = _set_background
@export var ambience: AudioStream : set = _set_ambience

@export_group("Configuration")
@export var _ambience: AudioStreamPlayer
@export var _background: PackedScene

var _current_background: TextureRect

var story_page: StoryPage :
	set(new_story_page):
		if story_page == new_story_page: return
		story_page = new_story_page
		_set_background(story_page.get_background())
		_set_ambience(story_page.get_ambience())

func _set_background(background_texture: Texture) -> void:
	background = background_texture
	if background_texture == null or (_current_background!= null and _current_background.texture == background_texture): return
	var new_background: TextureRect = _background.instantiate()
	if _current_background:
		_current_background.add_sibling(new_background)
	else:
		_ambience.add_sibling(new_background)
	new_background.texture = background_texture
	if _current_background != null:
		var tween: Tween = create_tween()
		tween.tween_property(new_background, "modulate:a", 1.0, 2.0).from(0.0)
		await tween.finished
		remove_child(_current_background)
		_current_background.queue_free()
	_current_background = new_background

func _set_ambience(audio_stream: AudioStream) -> void:
	ambience = audio_stream
	if audio_stream == null or _ambience.stream == audio_stream: return
	_ambience.stream = audio_stream
	if not Engine.is_editor_hint() and is_inside_tree(): _ambience.play()
