@tool
class_name CharacterPortrait
extends CharacterPanel

signal character_selected(character: Character)

@export var _portrait_identifier: String = "Small.png"

@export_group("Configuration")
@export var _button: DisplayButton

func setup(button_group: ButtonGroup) -> void:
	_button.button_group = button_group

func select() -> void:
	if not _button.button_pressed: _button.button_pressed = true
	else: character_selected.emit(character)

func _update() -> void:
	var character_profile: CharacterProfile = character.character_profile
	_portrait.texture = character_profile.get_portrait(_portrait_identifier)

func _update_portrait() -> void:
	_portrait.texture = _character_profile.get_portrait(_portrait_identifier)

func _set_character(new_character: Character) -> void:
	assert(new_character)
	if character != null:
		character.save_requested.disconnect(_on_save_requested)
		character.fight_requested.disconnect(_on_fight_requested)
	super._set_character(new_character)
	character.save_requested.connect(_on_save_requested)
	character.fight_requested.connect(_on_fight_requested)

func _on_save_requested(_save_request: SaveRequest) -> void:
	select()

func _on_fight_requested(_fight_request: FightRequest) -> void:
	select()

func _on_button_pressed() -> void:
	character_selected.emit(character)
