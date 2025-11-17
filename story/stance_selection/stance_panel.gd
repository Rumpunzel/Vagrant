@tool
class_name StancePanel
extends CarouselPanel

@export var attribute: CharacterAttribute :
	set(new_attribute):
		assert(new_attribute)
		attribute = new_attribute
		var descriptor: String = attribute.descriptor
		if not _descriptor_resolver.is_null(): descriptor = _descriptor_resolver.call(attribute)
		setup(descriptor)
		_icon.attribute = attribute
		label.add_theme_color_override("font_color", attribute.color)
		_tooltip_trigger.tooltip_strings = attribute.abilities

@export_group("Configuration")
@export var _tooltip_trigger: TooltipTrigger
@export var _icon: AttributeIcon

var _descriptor_resolver: Callable

func setup_for_fight(fight_request: FightRequest) -> void:
	if fight_request: _descriptor_resolver = func(selected_attribute: CharacterAttribute) -> String: return fight_request.get_stance_description(selected_attribute)
	else: _descriptor_resolver = Callable()
	attribute = fight_request.attribute
