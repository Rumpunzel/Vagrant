@tool
class_name CharacterAttributesPanel
extends PanelContainer

@export var character: Character :
	set(new_charater):
		assert(new_charater)
		character = new_charater
		character.character_profile_changed.connect(_on_character_profile_changed)
		character.injuries_changed.connect(_on_injuries_changed)
		if not is_node_ready(): await ready
		update_attributes()

@export_group("Configuration")
@export var _attributes: FlexContainer
@export var _attribute_score: PackedScene

var _attribute_scores: Dictionary[CharacterAttribute, CharacterSheetAttributeScore] = { }

func _ready() -> void:
	assert(_attribute_scores.is_empty())
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var attribute_score: CharacterSheetAttributeScore = _attribute_score.instantiate()
		attribute_score.attribute = attribute as CharacterAttribute
		_attribute_scores[attribute] = attribute_score
		_attributes.add(attribute_score)

func update_attributes() -> void:
	assert(character)
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var attribute_score: CharacterSheetAttributeScore = _attribute_scores[attribute]
		attribute_score.score = character.get_attribute_score(attribute)

func _on_character_profile_changed(character_profile: CharacterProfile) -> void:
	assert(character_profile == character.character_profile)
	update_attributes()

func _on_injuries_changed(injuries: Array[Injury]) -> void:
	assert(injuries == character.injuries)
	update_attributes()
