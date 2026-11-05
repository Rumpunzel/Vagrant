@tool
extends EditorPlugin

const MANAGER: String = "TooltipManager"


func _enable_plugin() -> void:
	add_autoload_singleton(MANAGER, "res://addons/tooltips_pro/scripts/tooltip_manager.gd")

	var primary_key: InputEventKey = InputEventKey.new()
	primary_key.physical_keycode = KEY_T
	var secondary_key: InputEventMouseButton = InputEventMouseButton.new()
	secondary_key.device = -1
	secondary_key.button_index = MOUSE_BUTTON_MIDDLE

	var input: Dictionary = {
		"deadzone": 0.2,
		"events": [
			primary_key,
			secondary_key
		]
	}
	ProjectSettings.set_setting("input/lock_tooltip", input)
	ProjectSettings.save()


func _disable_plugin() -> void:
	remove_autoload_singleton(MANAGER)

	ProjectSettings.set_setting("input/lock_tooltip", null)
	ProjectSettings.save()
