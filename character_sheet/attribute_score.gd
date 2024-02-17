@tool
class_name CharacterSheetAttributeScore
extends HBoxContainer

@export_group("Configuration")
@export var _descriptor: Label
@export var _score: SpinBox

var attribute: CharacterAttribute :
	set(new_attribute):
		attribute = new_attribute
		_descriptor.text = attribute.descriptor

var score: int :
	set(new_score):
		score = new_score
		_score.value = score
