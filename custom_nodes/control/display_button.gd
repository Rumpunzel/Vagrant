@tool
class_name DisplayButton
extends Button

signal activation_changed(new_status: bool)

@export var active: bool = true :
	set(new_status):
		if new_status == active: return
		active = new_status
		button_mask = MOUSE_BUTTON_MASK_LEFT if active else 0
		focus_mode = Control.FOCUS_ALL if active else Control.FOCUS_NONE
		mouse_filter = Control.MOUSE_FILTER_STOP if active else Control.MOUSE_FILTER_PASS
		activation_changed.emit(active)
