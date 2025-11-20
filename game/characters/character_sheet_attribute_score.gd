@tool
class_name CharacterSheetAttributeScore
extends PanelContainer

@export var attribute: CharacterAttribute :
	set(new_attribute):
		attribute = new_attribute
		if not is_node_ready(): await ready
		_icon.attribute = attribute
		_score.text = ""
@export var font_size: int = 96:
	get: return _score.get_theme_font_size("font_size")
	set(new_font_size): _score.add_theme_font_size_override("font_size", new_font_size)

@export_group("Configuration")
@export var _icon: AttributeIcon
@export var _tooltip_trigger: TooltipTrigger
@export var _score: Label

var score: AttributeScore :
	set(new_score):
		score = new_score
		_score.text = "%d" % score.get_score()
		_score.modulate = score.get_color()
		_tooltip_trigger.tooltip_strings = [score.get_details()]
