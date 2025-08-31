class_name Character
extends Node

signal character_profile_changed(character_profile: CharacterProfile)
signal attribute_scores_changed(character: Character)
signal breath_dice_changed(breath_dice: Array[BreathDie])

const GROUP: StringName = "Characters"

@export var character_profile: CharacterProfile :
	set(new_character_profile):
		if new_character_profile == character_profile: return
		character_profile = new_character_profile
		name = character_profile.name
		portrait = character_profile.portrait
		attribute_scores = character_profile.get_attribute_scores()
		breath_dice = character_profile.get_breath_dice()
		character_profile_changed.emit(character_profile)

var portrait: Texture

var attribute_scores: Dictionary[CharacterAttribute, AttributeScore] :
	set(new_attribute_scores):
		if new_attribute_scores == attribute_scores: return
		attribute_scores = new_attribute_scores
		attribute_scores_changed.emit(self)

var breath_dice: Array[BreathDie] :
	set(new_breath_dice):
		if new_breath_dice == breath_dice: return
		breath_dice = new_breath_dice
		breath_dice_changed.emit(breath_dice)

func get_attribute_score(attribute: CharacterAttribute) -> AttributeScore:
	return attribute_scores.get(attribute)

func get_available_breath_dice() -> Array[BreathDie]:
	return breath_dice.filter(func(die: BreathDie) -> bool: return die.is_alive())

func get_breath_dice_count(breath_die_type: DieType, include_exhausted: bool = false) -> int:
	var count: int = 0
	for die: BreathDie in breath_dice: if die.die_type == breath_die_type and (include_exhausted or die.is_alive()): count +=1
	return count
