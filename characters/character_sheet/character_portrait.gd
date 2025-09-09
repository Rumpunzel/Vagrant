class_name CharacterPortrait
extends PanelContainer

@export var character: Character :
	set(new_character):
		if new_character == character: return
		if character != null:
			character.character_profile_changed.disconnect(_on_character_profile_changed)
			character.breath_dice_changed.disconnect(_breath_dice.setup_breath_dice)
			character.save_requested.disconnect(_breath_dice.update_save_request)
			character.save_rolled.disconnect(_breath_dice.update_save_result)
		character = new_character
		character.character_profile_changed.connect(_on_character_profile_changed)
		character.breath_dice_changed.connect(_breath_dice.setup_breath_dice)
		character.save_requested.connect(_breath_dice.update_save_request)
		character.save_rolled.connect(_breath_dice.update_save_result)
		_update()
		_breath_dice.setup_breath_dice(character.breath_dice)

@export var _portrait_identifier: String = "Small.png"

@export_group("Configuration")
@export var _portrait: TextureRect
@export var _breath_dice: BreathDiceSelectionButtons

func _update() -> void:
	var character_profile: CharacterProfile = character.character_profile
	name = character_profile.name
	_portrait.texture = character_profile.get_portrait(_portrait_identifier)

func _on_character_profile_changed(_character_profile: CharacterProfile) -> void:
	_update()
