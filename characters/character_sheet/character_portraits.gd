class_name CharacterPortraits
extends PanelContainer

signal character_selected(character: Character, character_portrait: CharacterPortrait)

@export var characters: Characters :
	set(new_characters):
		assert(not characters)
		characters = new_characters
		_update_character_list(characters.characters)
		characters.characters_updated.connect(_update_character_list)

@export_group("Configuration")
@export var _portraits: FlexContainer
@export var _character_portrait: PackedScene

func _update_character_list(updated_characters: Dictionary[CharacterProfile, Character]) -> void:
	_portraits.clear()
	var button_group: ButtonGroup = ButtonGroup.new()
	for character: Character in updated_characters.values():
		var character_portrait: CharacterPortrait = _character_portrait.instantiate()
		character_portrait.character = character
		character_portrait.setup(button_group)
		character_portrait.character_selected.connect(character_selected.emit.bind(character_portrait))
		_portraits.add(character_portrait)
