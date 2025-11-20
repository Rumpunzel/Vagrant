class_name Character
extends Node

signal caught_breath(recovered_dice: Array[BreathDie])
signal suffered_injury(injury: Injury)

signal character_profile_changed(character_profile: CharacterProfile)
signal injuries_changed(injuries: Array[Injury])
signal breath_dice_changed(breath_dice: Array[BreathDie])
signal breath_dice_states_changed
signal exhaustion_changed(exhaustion: Array[DieType])

@export var character_profile: CharacterProfile :
	set(new_character_profile):
		if new_character_profile == character_profile: return
		character_profile = new_character_profile
		breath_dice = character_profile.get_breath_dice()
		character_profile_changed.emit(character_profile)

@export var exhaustion: Array[DieType] :
	set(new_exhaustion):
		if new_exhaustion == exhaustion: return
		exhaustion = new_exhaustion
		exhaustion.sort_custom(DieType.compare_ascending)
		exhaustion_changed.emit(exhaustion)

var breath_dice: Array[BreathDie] :
	set(new_breath_dice):
		if new_breath_dice == breath_dice: return
		for breath_die: BreathDie in breath_dice: breath_die.state_changed.disconnect(_on_breath_die_state_changed)
		breath_dice = new_breath_dice
		breath_dice.sort_custom(BreathDie.compare_ascending)
		for breath_die: BreathDie in breath_dice:
			assert(breath_die.alive)
			breath_die.state_changed.connect(_on_breath_die_state_changed.bind(breath_die))
		breath_dice_changed.emit(breath_dice)

var most_recently_chosen_attribute: CharacterAttribute

# TODO: if you roll under an injury, increase magnitude by 1
var _injuries: Array[Injury] :
	set(new_injuries):
		if new_injuries == _injuries: return
		_injuries = new_injuries
		injuries_changed.emit(_injuries)

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
	var recovered_breath_dice: Array[BreathDie] = []
	var recoverable_breath_dice: Dictionary[DieType, int] = get_recoverable_breath_dice(die_to_exhaust)
	for breath_die_type: DieType in recoverable_breath_dice.keys():
		assert(not exhaustion.has(breath_die_type))
		var dice_to_recover: int = recoverable_breath_dice[breath_die_type]
		recovered_breath_dice.append_array(breath_die_type.get_breath_dice_pool(dice_to_recover))
	var new_breath_dice: Array[BreathDie] = breath_dice.duplicate()
	new_breath_dice.append_array(recovered_breath_dice)
	assert(breath_dice != new_breath_dice)
	breath_dice = new_breath_dice
	caught_breath.emit(recovered_breath_dice)

func can_catch_breath(die_to_exhaust: DieType) -> bool:
	return not get_recoverable_breath_dice(die_to_exhaust).is_empty() and get_available_exhaustion().size() > 1

func get_lost_breath_dice() -> Dictionary[DieType, int]:
	var lost_breath_die_types: Dictionary[DieType, int] = {}
	var breath_die_types: Dictionary[DieType, int] = character_profile.breath_die_types
	for die_type: DieType in breath_die_types.keys():
		var missing_dice_count: int = breath_die_types[die_type]
		for breath_die: BreathDie in breath_dice: if breath_die.die_type == die_type: missing_dice_count -= 1
		if missing_dice_count > 0: lost_breath_die_types[die_type] = missing_dice_count
	return lost_breath_die_types

func get_recoverable_breath_dice(die_to_exhaust: DieType) -> Dictionary[DieType, int]:
	var recoverable_breath_dice: Dictionary[DieType, int] = get_lost_breath_dice()
	recoverable_breath_dice.erase(die_to_exhaust)
	for die_type: DieType in exhaustion: recoverable_breath_dice.erase(die_type)
	return recoverable_breath_dice

func get_breath_dice_count(breath_die_type: DieType) -> int:
	var count: int = 0
	for die: BreathDie in breath_dice: if die.die_type == breath_die_type: count +=1
	return count

func get_auto_selected_breath_dice(with_attribute: CharacterAttribute) -> Array[BreathDie]:
	var attribute_score: AttributeScore = get_attribute_score(with_attribute)
	return breath_dice.filter(func(die: BreathDie) -> bool: return die.is_auto_selected(attribute_score))

func get_available_exhaustion() -> Array[DieType]:
	var unexhausted_die_types: Array[DieType] = []
	var breath_die_types: Dictionary[DieType, int] = character_profile.breath_die_types
	unexhausted_die_types.assign(breath_die_types.keys().filter(func(die_type: DieType) -> bool: return not exhaustion.has(die_type)))
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

func _on_breath_die_state_changed(alive: bool, breath_die: BreathDie) -> void:
	assert(breath_die.alive == alive)
	if not alive: breath_dice.erase(breath_die)
	breath_dice_states_changed.emit()
