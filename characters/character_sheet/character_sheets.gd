class_name CharacterSheets
extends TabContainer

@export var _character_sheet: PackedScene

var _characters: Characters

func setup(characters: Characters) -> void:
	_characters = characters
	_update_character_list(_characters.characters)
	_characters.characters_updated.connect(_update_character_list)

func _update_character_list(characters: Dictionary[CharacterProfile, Character]) -> void:
	for child: Node in get_children():
		remove_child(child)
		child.queue_free()
	for character: Character in characters.values():
		var character_sheet: CharacterSheet = _character_sheet.instantiate()
		add_child(character_sheet)
		character_sheet.character = character
	var company_sheet: PanelContainer = PanelContainer.new()
	company_sheet.name = "Company"
	add_child(company_sheet)
