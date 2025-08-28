@tool
class_name CharacterAttributesPanel
extends HBoxContainer

@export var _attribute_score: PackedScene

var _attribute_scores: Dictionary[CharacterAttribute, CharacterSheetAttributeScore] = { }

func _ready() -> void:
	_setup()

func update_attributes(character: Character) -> void:
	_setup()
	for attribute: CharacterAttribute in _attribute_scores.keys():
		var attribute_score: CharacterSheetAttributeScore = _attribute_scores[attribute]
		attribute_score.score = character.get_attribute_score(attribute)

func _setup() -> void:
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var attribute_score: CharacterSheetAttributeScore = _attribute_score.instantiate()
		attribute_score.attribute = attribute as CharacterAttribute
		_attribute_scores[attribute] = attribute_score
		add_child(attribute_score)
