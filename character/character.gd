class_name Character
extends Node

signal attributes_changed

enum Attributes {
	MUSCLE,
	BLOOD,
	GUTS,
	BRAIN,
	NERVE,
	HEART,
}

@export var portrait: Texture = preload("res://portraits/knight.jpeg")

@export var _starting_attributes: CharacterAttributes = null

var muscle := 0 :
	get:
		return muscle - get_wound_total()
	set(new_muscle):
		muscle = new_muscle
		attributes_changed.emit()

var blood := 0 :
	get:
		return blood - get_wound_total()
	set(new_blood):
		blood = new_blood
		attributes_changed.emit()

var guts := 0 :
	get:
		return guts - get_wound_total()
	set(new_guts):
		guts = new_guts
		attributes_changed.emit()

var brain := 0 :
	get:
		return brain - get_wound_total()
	set(new_brain):
		brain = new_brain
		attributes_changed.emit()

var nerve := 0 :
	get:
		return nerve - get_wound_total()
	set(new_nerve):
		nerve = new_nerve
		attributes_changed.emit()

var heart := 0 :
	get:
		return heart - get_wound_total()
	set(new_heart):
		heart = new_heart
		attributes_changed.emit()

var hit_dice := DicePool.get_full_set()

var wounds := [ ]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_initialize_character()

func roll_save(attribute: Attributes) -> DiceRoller.DieResult:
	return DiceRoller.roll_save(hit_dice, self, attribute)

func get_attribute_score(attribute: Attributes) -> int:
	match attribute:
		Attributes.MUSCLE:
			return muscle
		Attributes.BLOOD:
			return blood
		Attributes.GUTS:
			return guts
		Attributes.BRAIN:
			return brain
		Attributes.NERVE:
			return nerve
		Attributes.HEART:
			return heart
	assert(false)
	return 0

func get_wound_total() -> int:
	return 0

func _initialize_character() -> void:
	if _starting_attributes == null:
		_starting_attributes = CharacterAttributes.new()
		_starting_attributes.roll_stats()
	muscle = _starting_attributes.muscle
	blood = _starting_attributes.blood
	guts = _starting_attributes.guts
	brain = _starting_attributes.brain
	nerve = _starting_attributes.nerve
	heart = _starting_attributes.heart
