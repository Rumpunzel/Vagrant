class_name SaveRequest
extends DiceRequest

func _init(for_character: Character, with_attribute: CharacterAttribute, source: AdventureSaveDecision) -> void:
	super(for_character, with_attribute, source)

func get_source() -> AdventureSaveDecision: return _source
func get_difficulty() -> int: return get_source().difficulty

func _create_result() -> SaveResult: return SaveResult.new(self)
