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
@export var _past_modulate: Color = Color(1.0, 1.0, 1.0, 0.25)

@export_group("Configuration")
@export var _background: BackgroundRect
@export var _body_container: Container

## Kept apart from the story page: an entry built again from a [PageRecord] has none
var _page_background: Texture2D
var _area_background: Texture2D
## [method become_past] without fading
var _instantly: bool = false

## Turns into a past page: fading, or [param instantly] (an entry built again from a [PageRecord])
func become_past(instantly: bool = false) -> void:
	_instantly = instantly
	state = State.PAST

func setup_page(new_story_page: StoryPage) -> void:
	set_story_page(new_story_page)
	_page_background = new_story_page.background
	_area_background = new_story_page.area_background

func enter_page() -> void:
	@warning_ignore("unsafe_method_access")
	Stage.enter_story_page(get_story_page())

@abstract func display_dice_result(dice_result: DiceRequestResult) -> void

@abstract func is_dice_page() -> bool

@abstract func get_story_page() -> StoryPage
@abstract func set_story_page(new_story_page: StoryPage) -> void

func _set_state(new_state: State) -> void:
	state = new_state
	match state:
		State.PAST:
			var duration: float = 0.0 if _instantly else _fade_out_duration
			var delay: float = 0.0 if _instantly else _fade_out_delay
			_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			if not _background.texture:
				var self_tween: Tween = create_tween()
				self_tween.tween_property(self, "self_modulate", Color.TRANSPARENT, duration).set_delay(delay)
				_background.texture = _area_background
				_background.fade_in()
			var tween: Tween = create_tween()
			tween.tween_property(_body_container, "modulate", _past_modulate, duration).set_delay(delay)
			await tween.finished
			for child: Control in get_children(): child.mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
			mouse_entered.connect(_on_mouse_entered)
			mouse_exited.connect(_on_mouse_exited)
		State.PRESENT:
			self_modulate = Color.TRANSPARENT if _background.texture else Color.WHITE
		_: assert(false, "StoryEntry.State %s is not supported!" % state)

func _on_mouse_entered() -> void:
	assert(state == State.PAST)
	if _page_background: _background.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	var tween: Tween = create_tween()
	tween.tween_property(_body_container, "modulate", Color.WHITE, _fade_in_duration)

func _on_mouse_exited() -> void:
	assert(state == State.PAST)
	if get_global_rect().has_point(get_viewport().get_mouse_position()): return
	_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	var tween: Tween = create_tween()
	tween.tween_property(_body_container, "modulate", _past_modulate, _fade_in_duration)
