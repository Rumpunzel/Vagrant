@tool
class_name CarouselPanel
extends PanelContainer

@export_group("Configuration")
@export var label: Label

func setup(text: String) -> void:
	label.text = text
