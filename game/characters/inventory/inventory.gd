@tool
class_name Inventory
extends PanelContainer

@export var _character_profile: CharacterProfile:
	set(new_character_profile):
		assert(new_character_profile)
		_character_profile = new_character_profile

func setup(character_profile: CharacterProfile) -> void:
	_character_profile = character_profile
