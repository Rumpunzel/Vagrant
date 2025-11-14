@tool
class_name AutoScrollContainer
extends HoverScrollContainer

@export_range(0.0, 5.0, 0.05, "or_greater") var _scroll_speed: float = 2.0
@export_range(0.0, 1024.0, 1.0, "or_greater", "suffix:px") var _scroll_overshoot: float = 64.0
@export var _auto_scroll_horizontally: bool
@export var _auto_scroll_vertically: bool

var _has_scrolled_horizontally_to: float = 0.0
var _has_scrolled_vertically_to: float = 0.0

func _ready() -> void:
	resized.connect(reset_scroll_tracking)

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	var h_scroll_bar: HScrollBar = get_h_scroll_bar()
	var h_max: float = h_scroll_bar.max_value - h_scroll_bar.page
	if _auto_scroll_horizontally and _has_scrolled_horizontally_to < h_scroll_bar.max_value - h_scroll_bar.page:
		var scroll_speed: float =(h_max - h_scroll_bar.value + _scroll_overshoot) * _scroll_speed
		h_scroll_bar.value += scroll_speed * delta
		_has_scrolled_horizontally_to = max(h_scroll_bar.value, _has_scrolled_horizontally_to)
	var v_scroll_bar: VScrollBar = get_v_scroll_bar()
	var v_max: float = v_scroll_bar.max_value - v_scroll_bar.page
	if _auto_scroll_vertically and _has_scrolled_vertically_to < v_max:
		var scroll_speed: float = (v_max - v_scroll_bar.value + _scroll_overshoot) * _scroll_speed
		v_scroll_bar.value += scroll_speed * delta
		_has_scrolled_vertically_to = max(v_scroll_bar.value, _has_scrolled_vertically_to)

func scroll_vertical_to_end() -> void:
	await get_tree().process_frame
	scroll_vertical = int(get_v_scroll_bar().max_value)

func reset_scroll_tracking() -> void:
	_has_scrolled_horizontally_to = 0.0
	_has_scrolled_vertically_to = 0.0
