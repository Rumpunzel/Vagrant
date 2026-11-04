class_name DiceLogEntry
extends PanelContainer

@warning_ignore("unused_private_class_variable")
@export_group("Configuration")
@export var _entry: TypingLabel

func get_text() -> String: return _entry.text

## As it was shown ([PageRecord]), without typing
func show_text(text: String) -> void: _entry.set_text_normally(text)
