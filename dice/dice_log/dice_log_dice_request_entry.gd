class_name DiceLogDiceRequestEntry
extends DiceLogSaveEntry

func initialize_dice_request(dice_request: DiceRequest) -> void:
	var attribute_prefix: String = _get_attribute_prefix(dice_request.character, dice_request.attribute)
	_entry.type_text("%s: Choose Breath Dice…" % attribute_prefix)
	dice_request.attribute_changed.connect(_on_attribute_changed.bind(dice_request.character))

func _update(character: Character, attribute: CharacterAttribute) -> void:
	var attribute_prefix: String = _get_attribute_prefix(character, attribute)
	_entry.type_text("%s: Choose Breath Dice…" % attribute_prefix)

func _on_attribute_changed(attribute: CharacterAttribute, character: Character) -> void:
	_update(character, attribute)
