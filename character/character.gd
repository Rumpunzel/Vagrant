class_name Character
extends Node

signal attribute_scores_changed(character: Character)
signal hit_dice_changed(hit_dice: DicePool)

@export var portrait: Texture = preload("res://portraits/knight.jpeg")

# CharacterAttribute -> int
@export var attribute_scores: Dictionary = {
	Rules.STRENGTH: 0,
	Rules.AGILITY: 0,
	Rules.CONSTITUTION: 0,
	Rules.INTELLIGENCE: 0,
	Rules.WILL: 0,
	Rules.CHARISMA: 0,
} :
	set(new_attribute_scores):
		attribute_scores = new_attribute_scores
		attribute_scores_changed.emit(new_attribute_scores)

var hit_dice: DicePool :
	set(new_hit_dice):
		if hit_dice != null: hit_dice.dice_pool_changed.disconnect(_on_dice_pool_changed)
		hit_dice = new_hit_dice
		if hit_dice != null: hit_dice.dice_pool_changed.connect(_on_dice_pool_changed)
		hit_dice_changed.emit(hit_dice)

var _maximum_hit_dice := DicePool.get_full_set()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	initialize_attributes()
	hit_dice = _maximum_hit_dice

func initialize_attributes() -> void:
	var attributes_changed := false
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		if get_attribute_score(attribute) == 0:
			attribute_scores[attribute] = DiceRoller.roll_sum(DicePool.get_2d6())
			attributes_changed = true
	if attributes_changed: attribute_scores_changed.emit(self)

func get_attribute_score(attribute: CharacterAttribute) -> int:
	return attribute_scores.get(attribute, 0)

func _on_dice_pool_changed(_new_pool: DicePool) -> void:
	hit_dice_changed.emit(hit_dice)
