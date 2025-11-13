@tool
class_name HoverScrollContainer
extends ScrollContainer

@onready var _default_horizontal_scroll_mode: ScrollMode = horizontal_scroll_mode
@onready var _default_vertical_scroll_mode: ScrollMode = vertical_scroll_mode

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func scroll_vertical_to_end() -> void:
	await get_tree().process_frame
	scroll_vertical = int(get_v_scroll_bar().max_value)

func _on_mouse_entered() -> void:
	if _default_horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE
	if _default_vertical_scroll_mode != SCROLL_MODE_DISABLED:
		vertical_scroll_mode = ScrollContainer.SCROLL_MODE_RESERVE

func _on_mouse_exited() -> void:
	horizontal_scroll_mode = _default_horizontal_scroll_mode
	vertical_scroll_mode = _default_vertical_scroll_mode
