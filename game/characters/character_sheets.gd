class_name CharacterSheets
extends TabContainer

@export var party: Party :
	set(new_party):
		assert(not party)
		party = new_party
		_update_character_list(party.characters)
		party.characters_updated.connect(_update_character_list)

@export_group("Configuration")
@export var _character_sheet: PackedScene

var _character_sheets: Dictionary[Character, CharacterSheet] = {}

func _update_character_list(updated_characters: Dictionary[CharacterProfile, Character]) -> void:
	var existing_characters: Array[Character] = updated_characters.values()
	var missing_character_count: int = existing_characters.size() - get_children().size()
	var superfluous_character_count: int = get_children().size() - existing_characters.size()
	
	for _i: int in range(missing_character_count):
		var character_sheet: CharacterSheet = _character_sheet.instantiate()
		add_child(character_sheet)
	for index: int in range(superfluous_character_count):
		var character_sheet: CharacterSheet = get_children()[_character_sheets.values().size() - index]
		remove_child(character_sheet)
		character_sheet.queue_free()
	
	_character_sheets.clear()
	for index: int in updated_characters.values().size():
		var character: Character = updated_characters.values()[index]
		var character_sheet: CharacterSheet = get_children()[index]
		character_sheet.character = character
		_character_sheets[character] = character_sheet
