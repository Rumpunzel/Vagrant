class_name SkippableTimer
extends Timer

func _unhandled_key_input(event: InputEvent) -> void:
	if is_stopped(): return
	if event.is_action_released("skip_dialog_typing"):
		stop()
		timeout.emit()
		get_viewport().set_input_as_handled()
