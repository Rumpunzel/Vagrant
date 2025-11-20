@tool
class_name AttributesRoller
extends FlexContainer

signal attributes_rolled(attribute_scores: Dictionary[CharacterAttribute, AttributeScore])

@export var _character_profile: CharacterProfile:
	set(new_character_profile):
		assert(new_character_profile)
		_character_profile = new_character_profile
		for attribute: CharacterAttribute in Rules.ATTRIBUTES:
			var attribute_score_roller: AttributeScoreRoller = _attribute_score_rollers[attribute]
			if not _character_profile.attribute_scores.has(attribute) or not _character_profile.attribute_scores.get(attribute): continue
			attribute_score_roller.score = _character_profile.attribute_scores[attribute]
			attribute_score_roller.disable()

@export_group("Configuration")
@export var _attribute_score_roller: PackedScene

var _attribute_score_rollers: Dictionary[CharacterAttribute, AttributeScoreRoller] = {}

func _ready() -> void:
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var attribute_score_roller: AttributeScoreRoller = _attribute_score_roller.instantiate()
		attribute_score_roller.attribute = attribute
		attribute_score_roller.attribute_score_rolled.connect(_on_attribute_score_rolled)
		_attribute_score_rollers[attribute] = attribute_score_roller
		add(attribute_score_roller)

func setup(character_profile: CharacterProfile) -> void:
	_character_profile = character_profile

func update_modifiers(modifiers: Array[AttributeScore.Modifier]) -> void:
	for_each_element(func(attribute_score_roller: AttributeScoreRoller) -> void: attribute_score_roller.modifiers = modifiers)

func _on_attribute_score_rolled(attribute: CharacterAttribute, attribute_score: RolledAttributeScore) -> void:
	_character_profile.attribute_scores[attribute] = attribute_score
	if _character_profile.has_valid_attributes(): attributes_rolled.emit(_character_profile.attribute_scores)
