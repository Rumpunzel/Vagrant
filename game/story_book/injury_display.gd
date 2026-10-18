class_name InjuryDisplay
extends HBoxContainer

@export_group("Configuration")
@export var _icon: TextureRect
@export var _magnitude: Label
@export var _target: Label

func setup(target_name: String, magnitude: int) -> void:
	assert(magnitude > 0)
	_icon.self_modulate = Main.FAILURE
	_magnitude.text = "%d" % magnitude
	_target.text = target_name
