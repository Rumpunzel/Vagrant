class_name DiceLogSaveRequestEntry
extends DiceLogSaveEntry

func initialize_save_request(save_request: SaveRequest, character_resolver: Callable) -> void:
	var character: Character = character_resolver.call(save_request.character_profile)
	var attribute_prefix: String = _get_attribute_prefix(character, save_request.attribute)
	_entry.type_text("%s: Choose Breath Dice…" % attribute_prefix)
