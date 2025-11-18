@tool
class_name AttributeIcon
extends TextureRect

@export var attribute: CharacterAttribute :
	set(new_attribute):
		assert(new_attribute)
		attribute = new_attribute
		texture = attribute.icon
		modulate = attribute.color * Color(1.0, 1.0, 1.0, _alpha_factor)

@export_range(0.0, 1.0, 0.05, "suffix:%") var _alpha_factor: float = 0.35
