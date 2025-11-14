@tool
class_name HoverScrollContainer
extends ScrollContainer

func _init() -> void:
	var h_hover_fade: HoverFade = _setup_scroll_bar(get_h_scroll_bar())
	var v_hover_fade: HoverFade = _setup_scroll_bar(get_v_scroll_bar())
	h_hover_fade.hover_neighbors = [v_hover_fade]
	v_hover_fade.hover_neighbors = [h_hover_fade]

func _setup_scroll_bar(scroll_bar: ScrollBar) -> HoverFade:
	var hover_fade: HoverFade = HoverFade.new()
	hover_fade.control_to_fade = scroll_bar
	scroll_bar.add_child(hover_fade)
	return hover_fade
