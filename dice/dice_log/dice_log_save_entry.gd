class_name DiceLogSaveEntry
extends DiceLogEntry

func initialize_dice_request(dice_request: DiceRequest) -> void:
	var prefix: String = _get_prefix(dice_request.character, dice_request.attribute)
	_entry.type_text("%s: Choose Breath Dice…" % prefix)
	dice_request.attribute_changed.connect(_on_attribute_changed.bind(dice_request.character))

func _update(character: Character, attribute: CharacterAttribute) -> void:
	var prefix: String = _get_prefix(character, attribute)
	_entry.type_text("%s: Choose Breath Dice…" % prefix)

func _get_prefix(character: Character, attribute: CharacterAttribute) -> String:
	return "%s" % [_get_attribute_prefix(character, attribute)]

func _get_character_prefix(character: Character) -> String:
	return "[font=uid://dhul84ic8fo8d]%s[/font]" % [character.character_profile.name]

func _get_attribute_prefix(character: Character, attribute: CharacterAttribute) -> String:
	var hint: String = "%s: %d" % [attribute, character.get_attribute_score(attribute).get_score()]
	return "[hint=%s]%s[/hint]" % [hint, attribute.to_bbcode()]

func _on_attribute_changed(attribute: CharacterAttribute, character: Character) -> void:
	_update(character, attribute)
