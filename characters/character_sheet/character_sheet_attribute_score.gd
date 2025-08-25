@tool
class_name CharacterSheetAttributeScore
extends PanelContainer

@export_group("Configuration")
@export var _color: ColorRect
@export var _icon: TextureRect
@export var _descriptor: Label
@export var _score: Label

var attribute: CharacterAttribute :
	set(new_attribute):
		attribute = new_attribute
		_color.color = attribute.color
		_icon.texture = attribute.icon
		_descriptor.text = attribute.descriptor

var score: AttributeScore :
	set(new_score):
		score = new_score
		_score.text = "%d" % score.get_score()
		tooltip_text = "[ %s ]" % score.get_dice()
