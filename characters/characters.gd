class_name Characters
extends Node

signal characters_updated(characters: Dictionary[CharacterProfile, Character])

@export var _character: PackedScene

var characters: Dictionary[CharacterProfile, Character] = { }

var _protagonist_profile: CharacterProfile

func create_character(character_profile: CharacterProfile) -> Character:
	assert(not characters.has(character_profile), "Character is not allowed to exist when being created!")
	var character: Character = _character.instantiate()
	add_child(character)
	character.character_profile = character_profile
	characters[character_profile] = character
	characters_updated.emit(characters)
	return character

func create_protagonist(character_profile: CharacterProfile) -> Character:
	_protagonist_profile = character_profile
	return create_character(character_profile)

func get_protagonist() -> Character:
	assert(_protagonist_profile)
	return characters[_protagonist_profile]

func get_character(character_profile: CharacterProfile, create_if_nonexistant: bool = false) -> Character:
	var character: Character = characters[character_profile]
	if character == null and create_if_nonexistant: character = create_character(character_profile)
	return character
