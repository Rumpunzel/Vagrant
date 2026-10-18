class_name Injury
extends RefCounted

const ICON: Texture2D = preload("uid://v3pkbe7jeme1")

var magnitude: int

var _injury_icon: Texture2D = ICON

## Wound icon followed by the magnitude, for rich text
static func to_bbcode(of_magnitude: int, icon_size: int = 20) -> String:
	return "[img color=#%s width=%d height=%d valign=center]%s[/img]%d" % [Main.FAILURE.to_html(), icon_size, icon_size, ICON.resource_path, of_magnitude]

func _init(new_magnitude: int) -> void:
	magnitude = new_magnitude

func to_attribute_score_modifier() -> AttributeScore.Modifier:
	var score_modifier: AttributeScoreModifier = AttributeScoreModifier.new()
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		score_modifier.score_modifiers[attribute] = -magnitude
	return AttributeScore.Modifier.new(score_modifier, _injury_icon, true)
