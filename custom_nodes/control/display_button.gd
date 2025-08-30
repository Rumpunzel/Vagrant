@tool
class_name DisplayButton
extends Button

signal activation_changed(new_status: bool)

@export var active_mouse_cursor: Control.CursorShape = Control.CURSOR_POINTING_HAND
@export var inactive_mouse_cursor: Control.CursorShape = Control.CURSOR_ARROW

var active: bool = true :
	set(new_status):
		if new_status == active: return
		active = new_status
		button_mask = MOUSE_BUTTON_MASK_LEFT if active else 0
		focus_mode = Control.FOCUS_ALL if active else Control.FOCUS_NONE
		mouse_default_cursor_shape = active_mouse_cursor if active else inactive_mouse_cursor
		activation_changed.emit(active)
