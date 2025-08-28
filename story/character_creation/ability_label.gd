@tool
class_name AbilityLabel
extends PanelContainer

@export var origin: Origin :
	set(new_origin):
		origin = new_origin
		if not origin:
			_label.text = _placeholder
			_icon.texture = null
			return
		_label.text = origin.ability
		_icon.texture = origin.icon

@export_multiline var _placeholder: String :
	set(new_placeholder):
		_placeholder = new_placeholder
		if not is_node_ready(): await ready
		if _label.text.is_empty(): _label.text = _placeholder

@export_group("Configuration")
@export var _icon: TextureRect
@export var _label: RichTextLabel
