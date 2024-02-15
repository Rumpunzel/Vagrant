@tool
extends VBoxContainer

@export var _attribute_score: PackedScene

# CharacterAttribute -> UIScene
var _attribute_scores := { }

func _ready() -> void:
	for attribute_score: CharacterSheetAttributeScore in _attribute_scores.values():
		remove_child(attribute_score)
		attribute_score.queue_free()
	
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var attribute_score := _attribute_score.instantiate()
		attribute_score.attribute = attribute as CharacterAttribute
		_attribute_scores[attribute] = attribute_score
		add_child(attribute_score)

func update_attributes(character: Character) -> void:
	for attribute: CharacterAttribute in _attribute_scores.keys():
		var attribute_score: CharacterSheetAttributeScore = _attribute_scores[attribute]
		if character != null:
			attribute_score.score = character.get_attribute_score(attribute)
		else:
			attribute_score.score = 0
