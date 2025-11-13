@tool
@abstract
class_name PageEntry
extends PanelContainer

enum State {
	PAST = -1,
	PRESENT,
}

@export var state: State = State.PRESENT : set = _set_state

@export_range(0.0, 1.0) var _fade_in_duration: float = 0.1
@export_range(0.0, 3.0) var _fade_out_duration: float = 1.0
@export_range(0.0, 1.0) var _fade_out_delay: float = 0.5
@export_range(0.0, 5.0) var _dice_fade_out_delay: float = 3.0
@export var _past_modulate: Color = Color(1.0, 1.0, 1.0, 0.25)

@export_group("Configuration")
@export var _background: BackgroundRect
@export var _body_container: Container

var _story: Story
var _characters: Characters

func setup_page(story: Story, characters: Characters, new_story_page: StoryPage) -> void:
	_story = story
	_characters = characters
	set_story_page(new_story_page)
	#var background: Texture2D = get_story_page().get_background(_story)
	#_background.texture = background
	#if background:
		#_background.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
		#_background.show_behind_parent = false
	#else:
		#_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		#_background.show_behind_parent = true

@abstract func enter_page() -> void

@abstract func is_dice_page() -> bool

@abstract func get_story_page() -> StoryPage
@abstract func set_story_page(new_story_page: StoryPage) -> void

func _get_fade_out_delay() -> float:
	return _dice_fade_out_delay if is_dice_page() else _fade_out_delay

func _set_state(new_state: State) -> void:
	state = new_state
	match state:
		State.PAST:
			_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			if not _background.texture:
				var self_tween: Tween = get_tree().create_tween()
				self_tween.tween_property(self, "self_modulate", Color.TRANSPARENT, _fade_out_duration).set_delay(_get_fade_out_delay())
				_background.texture = get_story_page().get_area_background()
				_background.fade_in()
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(_body_container, "modulate", _past_modulate, _fade_out_duration).set_delay(_get_fade_out_delay())
			await tween.finished
			mouse_entered.connect(_on_mouse_entered)
			mouse_exited.connect(_on_mouse_exited)
		State.PRESENT:
			self_modulate = Color.TRANSPARENT if _background.texture else Color.WHITE
		_: assert(false, "StoryEntry.State %s is not supported!" % state)

func _on_mouse_entered() -> void:
	assert(state == State.PAST)
	if get_story_page().get_background(_story): _background.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(_body_container, "modulate", Color.WHITE, _fade_in_duration)

func _on_mouse_exited() -> void:
	assert(state == State.PAST)
	if get_global_rect().has_point(get_viewport().get_mouse_position()): return
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(_body_container, "modulate", _past_modulate, _fade_in_duration)
