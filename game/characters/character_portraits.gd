@tool
class_name CharacterPortraits
extends CharacterList

signal character_selected(character: Character, character_portrait: CharacterPortrait)

@export_group("Configuration")
@export var _character_portrait: PackedScene

var _character_portraits: Dictionary[Character, CharacterPortrait] = {}

func _ready() -> void:
	if not Engine.is_editor_hint(): return
	var character_portrait: CharacterPortrait = _character_portrait.instantiate()
	_character_list.add(character_portrait)
	character_portrait.select()

func _create_character_entry(character: Character) -> CharacterPortrait:
	var character_portrait: CharacterPortrait = _character_portrait.instantiate()
	character_portrait.character = character
	_character_portraits[character] = character_portrait
	character_portrait.character_selected.connect(character_selected.emit.bind(character_portrait))
	return character_portrait

func _update_character_list(updated_characters: Dictionary[CharacterProfile, Character]) -> void:
	var button_group: ButtonGroup = ButtonGroup.new()
	super._update_character_list(updated_characters)
	var portraits: Array[CharacterPortrait] = _get_portraits()
	for portrait: CharacterPortrait in portraits: portrait.setup(button_group)
	if not portraits.is_empty():
		var first_portrait: CharacterPortrait = portraits.front()
		first_portrait.select()

func _get_portraits() -> Array[CharacterPortrait]:
	var portraits: Array[CharacterPortrait] = []
	portraits.assign(_character_list.get_elements())
	return portraits

func _on_dice_requested(dice_request: DiceRequest) -> void:
	if not dice_request: return
	_character_portraits[dice_request.character].select_no_signal()
