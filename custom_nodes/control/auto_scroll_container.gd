@tool
class_name AutoScrollContainer
extends HoverScrollContainer

@export_range(0.0, 1.0, 0.05, "suffix:pct / s") var _scroll_speed: float = 0.25
@export var _auto_scroll_horizontally: bool
@export var _auto_scroll_vertically: bool

var _has_scrolled_horizontally_to: float = 0.0
var _has_scrolled_vertically_to: float = 0.0

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	var h_scroll_bar: HScrollBar = get_h_scroll_bar()
	if _auto_scroll_horizontally and _has_scrolled_horizontally_to < h_scroll_bar.max_value - h_scroll_bar.page:
		h_scroll_bar.value = lerpf(h_scroll_bar.value, h_scroll_bar.max_value, _scroll_speed * delta)
		_has_scrolled_horizontally_to = max(h_scroll_bar.value, _has_scrolled_horizontally_to)
	var v_scroll_bar: VScrollBar = get_v_scroll_bar()
	if _auto_scroll_vertically and _has_scrolled_vertically_to < v_scroll_bar.max_value - v_scroll_bar.page:
		v_scroll_bar.value = lerpf(v_scroll_bar.value, v_scroll_bar.max_value, _scroll_speed * delta)
		_has_scrolled_vertically_to = max(v_scroll_bar.value, _has_scrolled_vertically_to)
