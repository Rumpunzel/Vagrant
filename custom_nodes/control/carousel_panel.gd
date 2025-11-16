@tool
class_name CarouselPanel
extends PanelContainer

@export_group("Configuration")
@export var tooltip_trigger: TooltipTrigger
@export var label: Label

func setup(text: String, tooltip_strings: Array[String] = []) -> void:
	label.text = text
	tooltip_trigger.tooltip_strings = tooltip_strings
