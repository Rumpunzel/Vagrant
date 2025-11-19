@abstract
class_name DiceRequest
extends RefCounted

signal character_changed(character: Character)
signal attribute_changed(attribute: CharacterAttribute)
signal selected_breath_dice_changed(selected_breath_dice: Array[BreathDie])

var character: Character : set = set_character
var attribute: CharacterAttribute : set = set_attribute
var selected_breath_dice: Array[BreathDie] :
	set(new_selected_breath_dice):
		selected_breath_dice = new_selected_breath_dice
		selected_breath_dice_changed.emit(selected_breath_dice)

func _init(for_character: Character, with_attribute: CharacterAttribute) -> void:
	character = for_character
	attribute = with_attribute

func select_breath_die(breath_die: BreathDie) -> void:
	if selected_breath_dice.has(breath_die): return
	selected_breath_dice.append(breath_die)
	selected_breath_dice.sort_custom(Die.compare_ascending)
	selected_breath_dice_changed.emit(selected_breath_dice)

func deselect_breath_die(breath_die: BreathDie) -> void:
	selected_breath_dice.erase(breath_die)
	selected_breath_dice_changed.emit(selected_breath_dice)

@abstract func get_description() -> String

func get_selected_dice() -> Array[Die]:
	var dice_snapshot: Array[Die] = []
	dice_snapshot.assign(selected_breath_dice)
	return dice_snapshot

func set_character(new_character: Character) -> void:
	assert(new_character)
	character = new_character
	if attribute: selected_breath_dice = character.get_auto_selected_breath_dice(attribute)
	character_changed.emit(character)

func set_attribute(new_attribute: CharacterAttribute) -> void:
	assert(new_attribute)
	attribute = new_attribute
	selected_breath_dice = character.get_auto_selected_breath_dice(attribute)
	attribute_changed.emit(attribute)
