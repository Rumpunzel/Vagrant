extends Node

const PROTAGONIST_PROFILE: CharacterProfile = preload("res://characters/protagonist.tres")

@export var _character: PackedScene
@export var eleanor: CharacterProfile = preload("res://characters/eleanor.tres")

# CharacterProfile -> Character
var characters := { }

func _ready() -> void:
	create_character(PROTAGONIST_PROFILE)
	create_character(eleanor)

func get_protagonist() -> Character:
	return get_character(PROTAGONIST_PROFILE)

func get_character(character_profile: CharacterProfile, create_if_nonexistant := false) -> Character:
	var character: Character = characters[character_profile]
	if character == null and create_if_nonexistant: character = create_character(character_profile)
	return character

func create_character(character_profile: CharacterProfile) -> Character:
	assert(not characters.has(character_profile), "Character is not allowed to exist when being created!")
	var character: Character = _character.instantiate()
	character.character_profile = character_profile
	characters[character_profile] = character
	add_child(character)
	return character
