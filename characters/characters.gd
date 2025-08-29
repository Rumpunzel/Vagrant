class_name Characters
extends Node

signal characters_updated(characters: Dictionary[CharacterProfile, Character])

@export var _character: PackedScene

var protagonist_profile: CharacterProfile
var characters: Dictionary[CharacterProfile, Character] = { }

func create_character(character_profile: CharacterProfile) -> Character:
	assert(not characters.has(character_profile), "Character is not allowed to exist when being created!")
	var character: Character = _character.instantiate()
	add_child(character)
	character.character_profile = character_profile
	characters[character_profile] = character
	characters_updated.emit(characters)
	return character

func get_protagonist() -> Character:
	assert(protagonist_profile)
	return characters[protagonist_profile]

func get_character(character_profile: CharacterProfile, create_if_nonexistant: bool = false) -> Character:
	var character: Character = characters[character_profile]
	if character == null and create_if_nonexistant: character = create_character(character_profile)
	return character
