@tool
extends VBoxContainer

@export var _attribute_score: PackedScene

# CharacterAttribute -> UIScene
var _attribute_scores := { }

func _ready() -> void:
	_setup()

func update_attributes(character: Character) -> void:
	_setup()
	for attribute: CharacterAttribute in _attribute_scores.keys():
		var attribute_score: CharacterSheetAttributeScore = _attribute_scores[attribute]
		attribute_score.score = character.get_attribute_score(attribute)

func _setup() -> void:
	if not _attribute_scores.is_empty(): return
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var attribute_score := _attribute_score.instantiate()
		attribute_score.attribute = attribute as CharacterAttribute
		_attribute_scores[attribute] = attribute_score
		add_child(attribute_score)
