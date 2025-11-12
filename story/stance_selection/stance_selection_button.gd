@tool
class_name StanceSelectionButton
extends DisplayButton

@export var attribute: CharacterAttribute :
	set(new_attribute):
		assert(new_attribute)
		attribute = new_attribute
		set_icon_colors(attribute.color)
		_tooltip_trigger.tooltip_strings = attribute.abilities

@export_group("Configuration")
@export var _tooltip_trigger: TooltipTrigger
