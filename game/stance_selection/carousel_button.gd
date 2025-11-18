@tool
class_name CarouselButton
extends DisplayButton

@export_group("Configuration")
@export var tooltip_trigger: TooltipTrigger

func setup(button_icon: Texture2D, tooltip_strings: Array[String] = []) -> void:
	icon = button_icon
	tooltip_trigger.tooltip_strings = tooltip_strings
