class_name Character
extends Node

signal attribute_scores_changed(character: Character)
signal hit_dice_changed(hit_dice: Array[Die])

const GROUP := "Characters"

@export var _portrait: Texture = preload("res://portraits/knight.jpeg")

@export_group("Attributes")
@export_range(0, 12) var _strength := 0
@export_range(0, 12) var _agility := 0
@export_range(0, 12) var _constitution := 0
@export_range(0, 12) var _intelligence := 0
@export_range(0, 12) var _will := 0
@export_range(0, 12) var _charisma := 0

@export_group("Hit Dice")
@export var _d4_hit_dice := 1
@export var _d6_hit_dice := 1
@export var _d8_hit_dice := 1
@export var _d10_hit_dice := 1
@export var _d12_hit_dice := 1

# CharacterAttribute -> int
var attribute_scores: Dictionary :
	set(new_attribute_scores):
		if new_attribute_scores == attribute_scores: return
		attribute_scores = new_attribute_scores
		attribute_scores_changed.emit(self)

var hit_dice: Array[Die] :
	set(new_hit_dice):
		if new_hit_dice == hit_dice: return
		hit_dice = new_hit_dice
		hit_dice_changed.emit(hit_dice)

var portrait := _portrait

func _enter_tree() -> void:
	add_to_group(GROUP)

func _ready() -> void:
	initialize_character()

func initialize_character() -> void:
	attribute_scores = {
		Rules.STRENGTH: _strength if _strength > 0 else DiceRoller.roll_sum(Rules.d6.get_dice_pool(2)),
		Rules.AGILITY: _agility if _agility > 0 else DiceRoller.roll_sum(Rules.d6.get_dice_pool(2)),
		Rules.CONSTITUTION: _constitution if _constitution > 0 else DiceRoller.roll_sum(Rules.d6.get_dice_pool(2)),
		Rules.INTELLIGENCE: _intelligence if _intelligence > 0 else DiceRoller.roll_sum(Rules.d6.get_dice_pool(2)),
		Rules.WILL: _will if _will > 0 else DiceRoller.roll_sum(Rules.d6.get_dice_pool(2)),
		Rules.CHARISMA: _charisma if _charisma > 0 else DiceRoller.roll_sum(Rules.d6.get_dice_pool(2)),
	}
	hit_dice = DiceRoller.generate_dice_pool(_d4_hit_dice, _d6_hit_dice, _d8_hit_dice, _d10_hit_dice, _d12_hit_dice)
	portrait = _portrait

func get_attribute_score(attribute: CharacterAttribute) -> int:
	return attribute_scores.get(attribute, 0)

func get_available_hit_dice() -> Array[Die]:
	var available_hit_dice: Array[Die] = [ ]
	for die: Die in hit_dice:
		if die.status == Die.Status.ALIVE: available_hit_dice.append(die)
	return available_hit_dice

func get_hit_dice_count(hit_die_type: DieType, include_exhausted := false) -> int:
	var count := 0
	for die: Die in hit_dice:
		if die.die_type == hit_die_type and (include_exhausted or die.status == Die.Status.ALIVE): count +=1
	return count
