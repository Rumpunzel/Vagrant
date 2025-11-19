@tool
class_name DieCarouselPanel
extends CarouselPanel

@export var die_type: DieType :
	set(new_die_type):
		die_type = new_die_type
		if not is_node_ready(): await ready
		if die_type:
			_icon.texture = die_type.icon
			_icon.visible = true
			label.visible = false
		else:
			_icon.visible = false
			label.visible = true

@export_group("Configuration")
@export var _icon: TextureRect
