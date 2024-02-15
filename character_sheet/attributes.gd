@tool
extends VBoxContainer

@export var _attribute_score: PackedScene

# CharacterAttribute -> UIScene
var _attribute_scores := { }

func _enter_tree() -> void:
	for attribute_score: CharacterSheetAttributeScore in _attribute_scores.values():
		remove_child(attribute_score)
		attribute_score.queue_free()
	
	for attribute: CharacterAttribute in CharacterAttributes.ALL:
		var attribute_score := _attribute_score.instantiate()
		attribute_score.attribute = attribute
		_attribute_scores[attribute] = attribute_score
		add_child(attribute_score)

func update_attributes(attributes: CharacterAttributes) -> void:
	for attribute: CharacterAttribute in _attribute_scores.keys():
		var attribute_score: CharacterSheetAttributeScore = _attribute_scores[attribute]
		if attributes != null:
			attribute_score.score = attributes.get_attribute_score(attribute)
		else:
			attribute_score.score = 0
