extends Node

const STRENGTH: CharacterAttribute = preload("res://characters/attributes/strength.tres")
const AGILITY: CharacterAttribute = preload("res://characters/attributes/agility.tres")
const CONSTITUTION: CharacterAttribute = preload("res://characters/attributes/constitution.tres")
const INTELLIGENCE: CharacterAttribute = preload("res://characters/attributes/intelligence.tres")
const WILL: CharacterAttribute = preload("res://characters/attributes/will.tres")
const CHARISMA: CharacterAttribute = preload("res://characters/attributes/charisma.tres")

const ATTRIBUTES: Array[CharacterAttribute] = [
	STRENGTH,
	AGILITY,
	CONSTITUTION,
	INTELLIGENCE,
	WILL,
	CHARISMA,
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
