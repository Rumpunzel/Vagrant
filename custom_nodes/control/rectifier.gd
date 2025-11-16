@tool
class_name Rectifier
extends Node

@export var control_to_rectify: Control :
	set(new_control_to_rectify):
		control_to_rectify = new_control_to_rectify
		if source_control: _on_source_control_resized()
@export var width_to_height_ratio: float = 0.0 :
	set(new_width_to_height_ratio):
		width_to_height_ratio = new_width_to_height_ratio
		if control_to_rectify and source_control: _on_source_control_resized()
@export var height_to_width_ratio: float = 0.0 :
	set(new_height_to_width_ratio):
		height_to_width_ratio = new_height_to_width_ratio
		if control_to_rectify and source_control: _on_source_control_resized()
@export var source_control: Control :
	set(new_source_control):
		source_control = new_source_control
		if control_to_rectify: _on_source_control_resized()
		source_control.resized.connect(_on_source_control_resized)

func _ready() -> void:
	if not control_to_rectify: control_to_rectify = get_parent()
	if not source_control: source_control = control_to_rectify.get_parent()
	assert(control_to_rectify)
	assert(source_control)
	assert(control_to_rectify != source_control)

func _on_source_control_resized() -> void:
	control_to_rectify.custom_minimum_size.x = source_control.size.y * width_to_height_ratio
	control_to_rectify.custom_minimum_size.y = source_control.size.x * height_to_width_ratio
