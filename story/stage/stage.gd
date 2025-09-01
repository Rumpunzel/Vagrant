@tool
class_name Stage
extends CanvasLayer

@export var background: Texture : set = _set_background
@export var ambience: AudioStream : set = _set_ambience
@export var music: AudioStream : set = _set_music

@export_group("Configuration")
@export var _ambience: AudioStreamPlayer
@export var _music: AudioStreamPlayer
@export var _backgrounds_container: Container
@export var _background: PackedScene

var _current_background: BackgroundRect

func set_story_page(story_page: StoryPage, story: Story) -> void:
	_set_background(story_page.get_area_background())
	_set_ambience(story_page.get_ambience(story))

func _set_background(background_texture: Texture2D) -> void:
	background = background_texture
	if background_texture == null or (_current_background and _current_background.texture == background_texture): return
	var new_background: BackgroundRect = _background.instantiate()
	_backgrounds_container.add_child(new_background)
	new_background.texture = background_texture
	if _current_background:
		_current_background.fade_out()
		new_background.fade_in()
	_current_background = new_background

func _set_ambience(audio_stream: AudioStream) -> void:
	if not audio_stream or _ambience.stream == audio_stream: return
	ambience = audio_stream
	_ambience.stream = audio_stream
	if not Engine.is_editor_hint() and is_inside_tree(): _ambience.play()

func _set_music(audio_stream: AudioStream) -> void:
	if _music.stream == audio_stream: return
	music = audio_stream
	_music.stream = audio_stream
	if not Engine.is_editor_hint() and is_inside_tree(): _music.play()
