@tool
extends Node

@export var _attributes_roller: AttributesRoller

func _on_attributes_rolled(attribute_scores: Dictionary[CharacterAttribute, AttributeScore]) -> void:
	print(attribute_scores)
	_attributes_roller.collapse()
