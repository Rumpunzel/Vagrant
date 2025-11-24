@abstract
class_name DiceRequest
extends RefCounted

signal rolled(dice_result: DiceResult)

signal character_changed(character: Character)
signal attribute_changed(attribute: CharacterAttribute)
signal selected_breath_dice_changed(selected_breath_dice: Dictionary[DieType, int])

var character: Character : set = set_character
var attribute: CharacterAttribute : set = set_attribute
var selected_breath_dice: Dictionary[DieType, int] :
	set(new_selected_breath_dice):
		selected_breath_dice = new_selected_breath_dice
		selected_breath_dice_changed.emit(selected_breath_dice)

var _source: AdventureDecision

func _init(for_character: Character, with_attribute: CharacterAttribute, source: AdventureDecision) -> void:
	character = for_character
	attribute = with_attribute
	_source = source

func roll() -> DiceRequestResult:
	var dice_result: DiceRequestResult = _create_result()
	rolled.emit(dice_result)
	return dice_result

func select_breath_die(breath_die: DieType) -> void:
	selected_breath_dice[breath_die] = selected_breath_dice.get_or_add(breath_die, 0) + 1
	selected_breath_dice_changed.emit(selected_breath_dice)

func deselect_breath_die(breath_die: DieType) -> void:
	assert(selected_breath_dice.get(breath_die, 0) > 0)
	selected_breath_dice[breath_die] = selected_breath_dice[breath_die] - 1
	selected_breath_dice_changed.emit(selected_breath_dice)

@abstract func get_source() -> AdventureDecision

func get_description() -> String: return get_source().description
func get_attribute_score() -> AttributeScore: return character.get_attribute_score(attribute)

func set_character(new_character: Character) -> void:
	assert(new_character)
	character = new_character
	if attribute: selected_breath_dice = character.get_auto_selected_breath_dice(attribute)
	character_changed.emit(character)

func set_attribute(new_attribute: CharacterAttribute) -> void:
	assert(new_attribute)
	attribute = new_attribute
	assert(character)
	selected_breath_dice = character.get_auto_selected_breath_dice(attribute)
	attribute_changed.emit(attribute)

@abstract func _create_result() -> DiceRequestResult
