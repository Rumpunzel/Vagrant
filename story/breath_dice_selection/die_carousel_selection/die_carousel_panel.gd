@tool
class_name DieCarouselPanel
extends CarouselPanel

@export var die_type: DieType :
	set(new_die_type):
		assert(new_die_type)
		die_type = new_die_type
		if not is_node_ready(): await ready
		_icon.texture = die_type.icon

@export_group("Configuration")
@export var _icon: TextureRect

func setup(_text: String) -> void: return
