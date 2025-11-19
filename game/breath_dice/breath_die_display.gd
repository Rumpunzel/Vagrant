@tool
class_name BreathDieDisplay
extends BreathDieButton

@export_group("Configuration")
@export var _shadow: TextureRect

func set_die_type(new_die_type: DieType) -> void:
	super.set_die_type(new_die_type)
	if not is_node_ready(): await ready
	_shadow.texture = die_type.icon_filled if icon else null
