class_name Character
extends Node

signal character_profile_changed(character_profile: CharacterProfile)
signal attribute_scores_changed(character: Character)
signal hit_dice_changed(hit_dice: Array[Die])

const GROUP: StringName = "Characters"

@export var character_profile: CharacterProfile :
	set(new_character_profile):
		if new_character_profile == character_profile: return
		character_profile = new_character_profile
		name = character_profile.name
		portrait = character_profile.portrait
		attribute_scores = character_profile.get_attribute_scores()
		hit_dice = character_profile.get_breath_dice()
		character_profile_changed.emit(character_profile)

var portrait: Texture

var attribute_scores: Dictionary[CharacterAttribute, AttributeScore] :
	set(new_attribute_scores):
		if new_attribute_scores == attribute_scores: return
		attribute_scores = new_attribute_scores
		attribute_scores_changed.emit(self)

var hit_dice: Array[Die] :
	set(new_hit_dice):
		if new_hit_dice == hit_dice: return
		hit_dice = new_hit_dice
		hit_dice_changed.emit(hit_dice)

func get_attribute_score(attribute: CharacterAttribute) -> AttributeScore:
	return attribute_scores.get(attribute)

func get_available_hit_dice() -> Array[Die]:
	var available_hit_dice: Array[Die] = [ ]
	for die: Die in hit_dice:
		if die.is_alive(): available_hit_dice.append(die)
	return available_hit_dice

func get_hit_dice_count(hit_die_type: DieType, include_exhausted: bool = false) -> int:
	var count: int = 0
	for die: Die in hit_dice:
		if die.die_type == hit_die_type and (include_exhausted or die.is_alive()): count +=1
	return count
