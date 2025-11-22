class_name CharacterSheets
extends TabContainer

signal character_selected(character: Character)

@export var party: Party :
	set(new_party):
		assert(not party)
		assert(new_party)
		party = new_party
		_update_character_list(party.characters)
		party.characters_updated.connect(_update_character_list)

@export_group("Configuration")
@export var _character_sheet: PackedScene

var _character_sheets: Dictionary[Character, CharacterSheet] = {}

func _update_character_list(updated_characters: Dictionary[CharacterProfile, Character]) -> void:
	_character_sheets.clear()
	_clear()
	for character: Character in updated_characters.values():
		var character_sheet: CharacterSheet = _character_sheet.instantiate()
		character_sheet.character = character
		_character_sheets[character] = character_sheet
		add_child(character_sheet)

func _clear() -> void:
	for character_sheet: CharacterSheet in get_children():
		remove_child(character_sheet)
		character_sheet.queue_free()

func _on_tab_changed(tab: int) -> void:
	if tab < 0: return
	var selected_character_sheet: CharacterSheet = get_child(tab)
	assert(selected_character_sheet)
	var selected_character: Character = selected_character_sheet.character
	assert(selected_character)
	character_selected.emit(selected_character)
