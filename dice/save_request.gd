class_name SaveRequest
extends DiceRequest

signal save_rolled(save_result: SaveResult)

var source: AdventureSaveDecision

func _init(
	for_character: Character,
	with_attribute: CharacterAttribute,
	adventure_decision: AdventureSaveDecision,
) -> void:
	super(for_character, with_attribute)
	source = adventure_decision

func roll_save() -> void:
	assert(character)
	var attribute_score: AttributeScore = character.get_attribute_score(attribute)
	for die: BreathDie in selected_breath_dice: die.roll_save(attribute_score.get_score())
	var save_result: SaveResult = SaveResult.new(self)
	save_rolled.emit(save_result)

func get_description() -> String:
	return source.description

func get_difficulty() -> int:
	return source.difficulty
