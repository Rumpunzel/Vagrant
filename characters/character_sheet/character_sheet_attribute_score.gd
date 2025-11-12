@tool
class_name CharacterSheetAttributeScore
extends PanelContainer

@export var attribute: CharacterAttribute :
	set(new_attribute):
		attribute = new_attribute
		if not is_node_ready(): await ready
		_icon.attribute = attribute
		_score.text = ""

@export_group("Configuration")
@export var _icon: AttributeIcon
@export var _tooltip_trigger: TooltipTrigger
@export var _score: Label

var score: AttributeScore :
	set(new_score):
		score = new_score
		_score.text = "%d" % score.get_score()
		_tooltip_trigger.tooltip_strings = [score.get_details()]
