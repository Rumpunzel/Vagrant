extends Node

@export var _character: PackedScene

var characters: Dictionary[CharacterProfile, Character] = { }

func get_character(character_profile: CharacterProfile, create_if_nonexistant: bool = false) -> Character:
	var character: Character = characters[character_profile]
	if character == null and create_if_nonexistant: character = create_character(character_profile)
	return character

func create_character(character_profile: CharacterProfile) -> Character:
	assert(not characters.has(character_profile), "Character is not allowed to exist when being created!")
	var character: Character = _character.instantiate()
	add_child(character)
	character.character_profile = character_profile
	characters[character_profile] = character
	return character
