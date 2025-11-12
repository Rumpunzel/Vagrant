@tool
class_name StanceSelection
extends PanelContainer

@export var attribute: CharacterAttribute :
	set(new_attribute):
		assert(new_attribute)
		attribute = new_attribute
		_tooltip_trigger.tooltip_strings = attribute.abilities
		_icon.texture = attribute.icon
		_icon.modulate = Color(1.0, 1.0, 1.0, 0.1) * attribute.color
		_descriptor.text = fight_request.get_stance_description(attribute) if fight_request else attribute.descriptor
		_descriptor.add_theme_color_override("default_color", attribute.color)

var fight_request: FightRequest :
	set(new_fight_request):
		assert(new_fight_request)
		fight_request = new_fight_request
		attribute = fight_request.attribute

@export_group("Configuration")
@export var _tooltip_trigger: TooltipTrigger
@export var _icon: TextureRect
@export var _descriptor: RichTextLabel
