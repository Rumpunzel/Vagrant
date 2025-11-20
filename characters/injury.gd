class_name Injury
extends RefCounted

var magnitude: int
var score_modifier: AttributeScoreModifier

var _injury_icon: Texture2D = load("uid://v3pkbe7jeme1")

func _init(new_magnitude: int) -> void:
	magnitude = new_magnitude
	score_modifier = AttributeScoreModifier.new()
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		score_modifier.score_modifiers[attribute] = magnitude

func to_attribute_score_modifier() -> AttributeScore.Modifier:
	return AttributeScore.Modifier.new(score_modifier, _injury_icon)
