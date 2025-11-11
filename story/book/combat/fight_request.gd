class_name FightRequest
extends DiceRequest

var source: StoryCombatPage

func _init(for_character: Character, story_page: StoryCombatPage) -> void:
	super(for_character, for_character.get_highest_attribute())
	source = story_page
	for_character.fight_requested.emit(self)

#func roll_save() -> SaveResult:
	#var attribute_score: AttributeScore = character.get_attribute_score(attribute)
	#for die: BreathDie in selected_breath_dice: die.roll_save(attribute_score.get_score())
	#var save_result: SaveResult = SaveResult.new(self)
	#character.save_rolled.emit(save_result)
	#character.continue_with_new_breath_dice()
	#return save_result

func get_decription() -> String:
	return source._description

func get_stance_description(for_attribute: CharacterAttribute) -> String:
	return source.stance_descriptions.get(for_attribute, for_attribute.stance_description)
