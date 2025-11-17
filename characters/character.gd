class_name Character
extends Resource

signal character_profile_changed(character_profile: CharacterProfile)
signal attribute_scores_changed(character: Character)
signal breath_dice_changed(breath_dice: Array[BreathDie])
signal breath_dice_states_changed

signal save_requested(save_request: SaveRequest)
signal save_rolled(save_result: SaveResult)
signal fight_requested(fight_request: FightRequest)
signal fight_rolled(fight_result: FightResult)

@export var character_profile: CharacterProfile :
	set(new_character_profile):
		if new_character_profile == character_profile: return
		character_profile = new_character_profile
		attribute_scores = character_profile.get_attribute_scores()
		breath_dice = character_profile.get_breath_dice()
		character_profile_changed.emit(character_profile)

var attribute_scores: Dictionary[CharacterAttribute, AttributeScore] :
	set(new_attribute_scores):
		if new_attribute_scores == attribute_scores: return
		attribute_scores = new_attribute_scores
		attribute_scores_changed.emit(self)

var breath_dice: Array[BreathDie] :
	set(new_breath_dice):
		if new_breath_dice == breath_dice: return
		for breath_die: BreathDie in breath_dice: breath_die.state_changed.disconnect(_on_breath_die_state_changed)
		breath_dice = new_breath_dice
		for breath_die: BreathDie in breath_dice: breath_die.state_changed.connect(_on_breath_die_state_changed)
		breath_dice_changed.emit(breath_dice)

func _init(new_character_profile: CharacterProfile = null) -> void:
	character_profile = new_character_profile

func request_save(save_request: SaveRequest) -> void:
	save_request.save_rolled.connect(_on_save_rolled)
	save_requested.emit(save_request)

func request_fight(fight_request: FightRequest) -> void:
	fight_request.fight_rolled.connect(_on_fight_rolled)
	fight_requested.emit(fight_request)

# The dice used for saves remain forever "laid on the table"
# Hence the charater may receive a new copy of thier breath dice to continue their adventure
func continue_with_new_breath_dice() -> void:
	breath_dice.assign(breath_dice.map(func(die: BreathDie) -> BreathDie: return die.duplicate()))
	breath_dice_changed.emit(breath_dice)

func can_catch_breath() -> bool:
	return not get_exhausted_breath_dice().is_empty() and not get_spendable_breath_dice().is_empty()

func get_portrait() -> Texture2D:
	return character_profile.portrait

func get_attribute_score(attribute: CharacterAttribute) -> AttributeScore:
	return attribute_scores.get(attribute)

func get_highest_attribute_score() -> AttributeScore:
	var highest_attribute_score: AttributeScore = null
	for attribute_score: AttributeScore in attribute_scores.values():
		if not highest_attribute_score or attribute_score.get_score() > highest_attribute_score.get_score():
			highest_attribute_score = attribute_score
	return highest_attribute_score

func get_highest_attribute() -> CharacterAttribute:
	var highest_attribute: CharacterAttribute = null
	var highest_attribute_score: AttributeScore = null
	for attribute: CharacterAttribute in attribute_scores.keys():
		var attribute_score: AttributeScore = attribute_scores[attribute]
		if not highest_attribute or attribute_score.get_score() > highest_attribute_score.get_score():
			highest_attribute = attribute
			highest_attribute_score = attribute_score
	return highest_attribute

func get_available_breath_dice() -> Array[BreathDie]:
	return breath_dice.filter(func(die: BreathDie) -> bool: return die.is_alive())

func get_breath_dice_count(breath_die_type: DieType, include_exhausted: bool = false) -> int:
	var count: int = 0
	for die: BreathDie in breath_dice: if die.die_type == breath_die_type and (include_exhausted or die.is_alive()): count +=1
	return count

func get_auto_selected_breath_dice(with_attribute: CharacterAttribute) -> Array[BreathDie]:
	return get_available_breath_dice().filter(func(die: BreathDie) -> bool: return die.is_auto_selected(get_attribute_score(with_attribute)))

func get_exhausted_breath_dice() -> Array[BreathDie]:
	return breath_dice.filter(func(die: BreathDie) -> bool: return die.is_exhausted())

func get_spendable_breath_dice() -> Array[BreathDie]:
	return breath_dice.filter(func(die: BreathDie) -> bool: return die.is_spendable())

func get_lost_breath_dice() -> Array[BreathDie]:
	return breath_dice.filter(func(die: BreathDie) -> bool: return die.is_lost())

func _on_save_rolled(save_result: SaveResult) -> void:
	save_result.save_request.save_rolled.disconnect(_on_save_rolled)
	save_rolled.emit(save_result)
	continue_with_new_breath_dice()

func _on_fight_rolled(fight_result: FightResult) -> void:
	fight_result.fight_request.fight_rolled.disconnect(_on_fight_rolled)
	fight_rolled.emit(fight_result)
	continue_with_new_breath_dice()

func _on_breath_die_state_changed(_state: BreathDie.State) -> void:
	breath_dice_states_changed.emit()
