class_name DiceLogSaveEntry
extends DiceLogEntry

func _get_attribute_prefix(character: Character, attribute: CharacterAttribute) -> String:
	var hint: String = "%s: %d" % [attribute, character.get_attribute_score(attribute).get_score()]
	return "[hint=%s][color=#%s][%s][/color][/hint]" % [hint, attribute.color.to_html(), attribute]
