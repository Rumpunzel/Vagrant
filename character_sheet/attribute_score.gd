@tool
class_name CharacterSheetAttributeScore
extends HBoxContainer

var attribute: CharacterAttribute :
	set(new_attribute):
		attribute = new_attribute
		%Descriptor.text = attribute.descriptor

var score: int :
	set(new_score):
		score = new_score
		%Score.value = score
