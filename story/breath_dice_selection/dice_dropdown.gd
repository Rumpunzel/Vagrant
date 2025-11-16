@tool
class_name DiceDropdown
extends OptionButton

func _ready() -> void:
	var popup: PopupMenu = get_popup()
	popup.add_theme_constant_override("icon_max_width", 32)
	popup
