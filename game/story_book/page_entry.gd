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
## A past page shows itself fully while the mouse is over it or one of its controls
var _hovered: bool = false
## Fading into or out of the past look; hovering takes it over
var _past_tween: Tween

func _ready() -> void: set_process(state == State.PAST and not Engine.is_editor_hint())

## Whether the mouse is over it, asked of the window rather than by mouse_entered / exited: those come from whichever control is
## topmost (entering straight onto a child skips the page), and miss the book scrolling under a mouse that doesn't move
func _process(_delta: float) -> void:
	if state != State.PAST: return
	var hovered_control: Control = get_viewport().gui_get_hovered_control()
	var hovered: bool = hovered_control != null and (hovered_control == self or is_ancestor_of(hovered_control))
	if hovered == _hovered: return
	_hovered = hovered
	if _past_tween: _past_tween.kill()
	_background.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL if hovered and _page_background else TextureRect.EXPAND_IGNORE_SIZE
	_past_tween = create_tween()
	_past_tween.tween_property(_body_container, "modulate", Color.WHITE if hovered else _past_modulate, _fade_in_duration)

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
			_past_tween = create_tween()
			_past_tween.tween_property(_body_container, "modulate", _past_modulate, duration).set_delay(delay)
			InertControls.make_inert(self)
			set_process(not Engine.is_editor_hint())
		State.PRESENT:
			self_modulate = Color.TRANSPARENT if _background.texture else Color.WHITE
		_: assert(false, "StoryEntry.State %s is not supported!" % state)
