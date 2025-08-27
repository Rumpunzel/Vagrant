@tool
class_name ItemContainer
extends VBoxContainer

@export var label: String :
	get: return _label.text
	set(new_label): _label.text = new_label

@export_group("Configuration")
@export var _label: Label
