class_name CharacterSheets
extends TabContainer

@export var characters: Characters :
	set(new_characters):
		assert(not characters)
		characters = new_characters
		_update_character_list(characters.characters)
		characters.characters_updated.connect(_update_character_list)

@export_group("Configuration")
@export var _character_sheet: PackedScene

func _update_character_list(updated_characters: Dictionary[CharacterProfile, Character]) -> void:
	for child: Node in get_children():
		if child is not CharacterSheet: continue
		remove_child(child)
		child.queue_free()
	for character: Character in updated_characters.values():
		var character_sheet: CharacterSheet = _character_sheet.instantiate()
		add_child(character_sheet)
		character_sheet.character = character
