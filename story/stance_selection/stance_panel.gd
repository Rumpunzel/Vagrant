@tool
class_name StancePanel
extends CarouselPanel

@export_group("Configuration")
@export var _icon: AttributeIcon

func setup_for_fight(fight_request: FightRequest) -> void:
	var attribute: CharacterAttribute = fight_request.attribute
	_icon.attribute = attribute
	setup(fight_request.get_stance_description(attribute) if fight_request else attribute.descriptor)
	label.add_theme_color_override("font_color", attribute.color)
	tooltip_trigger.tooltip_strings = attribute.abilities
