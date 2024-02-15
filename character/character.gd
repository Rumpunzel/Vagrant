class_name Character
extends Node

signal attributes_changed(attributes: CharacterAttributes)
signal hit_dice_changed(hit_dice: DicePool)

@export var portrait: Texture = preload("res://portraits/knight.jpeg")

@export var _starting_attributes: CharacterAttributes = null

var hit_dice: DicePool :
	set(new_hit_dice):
		if hit_dice != null: hit_dice.dice_pool_changed.disconnect(_on_dice_pool_changed)
		hit_dice = new_hit_dice
		if hit_dice != null: hit_dice.dice_pool_changed.connect(_on_dice_pool_changed)
		hit_dice_changed.emit(hit_dice)

var _attributes: CharacterAttributes :
	set(new_attributes):
		if _attributes != null: _attributes.attribute_scores_changed.disconnect(_on_attributes_changed)
		_attributes = new_attributes
		if _attributes != null: _attributes.attribute_scores_changed.connect(_on_attributes_changed)
		attributes_changed.emit(_attributes)

var _maximum_hit_dice := DicePool.get_full_set()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_attributes = CharacterAttributes.new()
	_attributes.initialize_attributes(_starting_attributes)
	hit_dice = _maximum_hit_dice

func roll_save(attribute: CharacterAttribute) -> DiceRoller.SaveResult:
	return DiceRoller.roll_save(hit_dice, self, attribute)

func get_attribute_score(attribute: CharacterAttribute) -> int:
	return _attributes.get_attribute_score(attribute)

func _on_attributes_changed(_new_attribute_scores: Dictionary) -> void:
	attributes_changed.emit(_attributes)

func _on_dice_pool_changed(_new_pool: DicePool) -> void:
	hit_dice_changed.emit(hit_dice)
