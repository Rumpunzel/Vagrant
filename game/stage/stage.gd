@tool
extends CanvasLayer

@export var area_background: Texture : set = _set_area_background
@export var event_background: Texture : set = _set_event_background
@export var ambience: AudioStream : set = _set_ambience
@export var music: AudioStream : set = _set_music

@export_group("Configuration")
@export var _ambience: AudioStreamPlayer
@export var _music: AudioStreamPlayer
@export var _area_backgrounds: Container
@export var _event_backgrounds: Container
@export var _background: PackedScene

var _current_area_background: BackgroundRect
var _current_event_background: BackgroundRect

func enter_story_page(story_page: StoryPage) -> void:
	_set_area_background(story_page.area_background)
	_set_event_background(story_page.background)
	_set_ambience(story_page.ambience)

func _set_area_background(background_texture: Texture2D) -> void:
	area_background = background_texture
	if _current_area_background and _current_area_background.texture == background_texture: return
	var old_background: BackgroundRect = _current_area_background
	var new_background: BackgroundRect = _background.instantiate()
	new_background.texture = background_texture
	_current_area_background = new_background
	_area_backgrounds.add_child(new_background)
	if old_background:
		await new_background.faded_in
		old_background.fade_out()

func _set_event_background(background_texture: Texture2D) -> void:
	event_background = background_texture
	if _current_event_background and _current_event_background.texture == background_texture: return
	var old_background: BackgroundRect = _current_event_background
	var new_background: BackgroundRect = _background.instantiate()
	new_background.texture = background_texture
	_current_event_background = new_background
	_event_backgrounds.add_child(new_background)
	if old_background:
		await new_background.faded_in
		old_background.fade_out()

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
