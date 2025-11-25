class_name Character
extends Node

signal caught_breath(recovered_dice: Dictionary[Die, int])
signal suffered_injury(injury: Injury)

signal character_profile_changed(character_profile: CharacterProfile)
signal injuries_changed(injuries: Array[Injury])
signal breath_dice_changed(breath_dice: Dictionary[Die, int])
signal exhaustion_changed(exhaustion: Array[DieType])

@export var character_profile: CharacterProfile :
	set(new_character_profile):
		if new_character_profile == character_profile: return
		character_profile = new_character_profile
		_recover_breath_dice()
		character_profile_changed.emit(character_profile)

@export var exhaustion: Array[DieType] :
	set(new_exhaustion):
		if new_exhaustion == exhaustion: return
		exhaustion = new_exhaustion
		exhaustion.sort_custom(DieType.compare_ascending)
		exhaustion_changed.emit(exhaustion)

var breath_dice: Dictionary[DieType, int] :
	set(new_breath_dice):
		if new_breath_dice == breath_dice: return
		breath_dice = new_breath_dice
		breath_dice_changed.emit(breath_dice)

var most_recently_chosen_attribute: CharacterAttribute

# TODO: if you roll under an injury, increase magnitude by 1
var _injuries: Array[Injury] :
	set(new_injuries):
		if new_injuries == _injuries: return
		_injuries = new_injuries
		injuries_changed.emit(_injuries)

func parse_dice_result(dice_result: DiceRequestResult) -> void:
	var new_breath_dice: Dictionary[DieType, int] = breath_dice.duplicate()
	for breath_die: Die in dice_result.get_lost_breath_dice():
		new_breath_dice[breath_die.die_type] = new_breath_dice[breath_die.die_type] - 1
		assert(new_breath_dice[breath_die.die_type] >= 0)
	breath_dice = new_breath_dice

func suffer_injury(injury: Injury) -> void:
	assert(injury.magnitude > 0)
	_injuries.append(injury)
	injuries_changed.emit(_injuries)
	suffered_injury.emit(injury)

func catch_breath(die_to_exhaust: DieType) -> void:
	assert(die_to_exhaust)
	assert(can_catch_breath(die_to_exhaust))
	assert(not exhaustion.has(die_to_exhaust))
	## Exhaustion
	var new_exhaustion: Array[DieType] = exhaustion.duplicate()
	new_exhaustion.append(die_to_exhaust)
	exhaustion = new_exhaustion
	## Breath Dice Recovery
	var recovered_breath_dice: Dictionary[DieType, int] = _recover_breath_dice()
	caught_breath.emit(recovered_breath_dice)

func can_catch_breath(die_to_exhaust: DieType) -> bool:
	return not get_recoverable_breath_dice(die_to_exhaust).is_empty() and get_available_exhaustion().size() > 1

func get_breath_dice_pool() -> Array[Die]:
	return DiceRoller.generate_dice_pool(breath_dice)

func get_recoverable_breath_dice(die_to_exhaust: DieType) -> Dictionary[DieType, int]:
	var recoverable_breath_dice: Dictionary[DieType, int] = {}
	for die_type: DieType in Rules.BREATH_DICE.keys():
		if die_to_exhaust == die_type or exhaustion.has(die_type): continue
		var max_die_count: int = Rules.BREATH_DICE[die_type]
		var recoverable: int = max_die_count - breath_dice.get(die_type, 0)
		if recoverable > 0: recoverable_breath_dice[die_type] = recoverable
	return recoverable_breath_dice

func get_breath_dice_count(breath_die_type: DieType) -> int: return breath_dice[breath_die_type]

func get_auto_selected_breath_dice(with_attribute: CharacterAttribute) -> Dictionary[DieType, int]:
	var attribute_score: AttributeScore = get_attribute_score(with_attribute)
	var auto_selected_breath_dice: Dictionary[DieType, int] = {}
	for die_type: DieType in breath_dice.keys(): if die_type.is_auto_selected(attribute_score): auto_selected_breath_dice[die_type] = breath_dice[die_type]
	return auto_selected_breath_dice

func get_available_exhaustion() -> Array[DieType]:
	var unexhausted_die_types: Array[DieType] = []
	unexhausted_die_types.assign(Rules.BREATH_DICE.keys().filter(func(die_type: DieType) -> bool: return not exhaustion.has(die_type)))
	return unexhausted_die_types

func get_smallest_exhaustion() -> DieType:
	var smallest_die_type: DieType = null
	for die_type: DieType in get_available_exhaustion():
		if not smallest_die_type or die_type.faces < smallest_die_type.faces: smallest_die_type = die_type
	return smallest_die_type

func get_portrait() -> Texture2D:
	return character_profile.portrait

func get_attribute_score(attribute: CharacterAttribute) -> AttributeScore:
	return AttributeScore.new(attribute, character_profile.attribute_scores[attribute], get_internal_attribute_modifiers(), get_external_attribute_modifiers())

func get_internal_attribute_modifiers() -> Array[AttributeScore.Modifier]:
	var modifiers: Array[AttributeScore.Modifier] = []
	modifiers.append_array(character_profile.get_attribute_modifiers())
	return modifiers

func get_external_attribute_modifiers() -> Array[AttributeScore.Modifier]:
	var modifiers: Array[AttributeScore.Modifier] = []
	for injury: Injury in _injuries: modifiers.append(injury.to_attribute_score_modifier())
	return modifiers

func get_highest_attribute_score() -> AttributeScore:
	var highest_attribute_score: AttributeScore = null
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var attribute_score: AttributeScore = get_attribute_score(attribute)
		if not highest_attribute_score or attribute_score.get_score() > highest_attribute_score.get_score():
			highest_attribute_score = attribute_score
	return highest_attribute_score

func get_favored_attribute() -> CharacterAttribute:
	return most_recently_chosen_attribute if most_recently_chosen_attribute else get_highest_attribute()

func get_highest_attribute() -> CharacterAttribute:
	var highest_attribute: CharacterAttribute = null
	var highest_attribute_score: AttributeScore = null
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var attribute_score: AttributeScore = get_attribute_score(attribute)
		if not highest_attribute or attribute_score.get_score() > highest_attribute_score.get_score():
			highest_attribute = attribute
			highest_attribute_score = attribute_score
	return highest_attribute

func _recover_breath_dice() -> Dictionary[DieType, int]:
	var new_breath_dice: Dictionary[DieType, int] = breath_dice.duplicate()
	var recovered_breath_dice: Dictionary[DieType, int] = {}
	for die_type: DieType in Rules.BREATH_DICE.keys():
		if exhaustion.has(die_type): continue
		var max_die_count: int = Rules.BREATH_DICE[die_type]
		var recovered: int = max_die_count - breath_dice.get(die_type, 0)
		if recovered > 0:
			new_breath_dice[die_type] = max_die_count
			recovered_breath_dice[die_type] = recovered
	breath_dice = new_breath_dice
	return recovered_breath_dice
