class_name CharacterSheet
extends PanelContainer

@export var character: Character :
	set(new_character):
		if new_character == character: return
		if character != null:
			character.character_profile_changed.disconnect(_on_character_profile_changed)
			character.attribute_scores_changed.disconnect(_attributes.update_attributes)
			character.breath_dice_changed.disconnect(_breath_dice.setup_breath_dice)
			character.save_requested.disconnect(_breath_dice.update_save_request)
			character.save_rolled.disconnect(_breath_dice.update_save_result)
		character = new_character
		character.character_profile_changed.connect(_on_character_profile_changed)
		character.attribute_scores_changed.connect(_attributes.update_attributes)
		character.breath_dice_changed.connect(_breath_dice.setup_breath_dice)
		character.save_requested.connect(_breath_dice.update_save_request)
		character.save_rolled.connect(_breath_dice.update_save_result)
		_update()
		_attributes.update_attributes(character)
		_breath_dice.setup_breath_dice(character.breath_dice)

@export_group("Configuration")
@export var _portrait: TextureRect
@export var _name: RichTextLabel
@export var _title: RichTextLabel
@export var _attributes: CharacterAttributesPanel
@export var _breath_dice: BreathDiceSelectionButtons
@export var _ability_labels: AbilityLabels

func _update() -> void:
	var character_profile: CharacterProfile = character.character_profile
	name = character_profile.name
	_portrait.texture = character_profile.portrait
	_name.text = character_profile.name
	_title.text = character_profile.get_title()
	_ability_labels.update_abilities(character_profile.origins)

func _on_character_profile_changed(_character_profile: CharacterProfile) -> void:
	_update()

func _on_save_dialog_file_selected(path: String) -> void:
	ResourceSaver.save(character.character_profile, path, ResourceSaver.FLAG_CHANGE_PATH)

func _on_load_dialog_file_selected(path: String) -> void:
	character.character_profile = ResourceLoader.load(path, "CharacterProfile")
