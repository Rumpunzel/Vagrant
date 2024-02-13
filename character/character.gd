class_name Character
extends Node

@export var attributes := CharacterAttributes.new()

var hit_dice := DicePool.get_full_set()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func roll_muscle_save() -> int:
	return hit_dice.roll_save(attributes.muscle)

func roll_blood_save() -> int:
	return hit_dice.roll_save(attributes.blood)

func roll_guts_save() -> int:
	return hit_dice.roll_save(attributes.guts)

func roll_brain_save() -> int:
	return hit_dice.roll_save(attributes.brain)

func roll_nerve_save() -> int:
	return hit_dice.roll_save(attributes.nerve)

func roll_heart_save() -> int:
	return hit_dice.roll_save(attributes.heart)
