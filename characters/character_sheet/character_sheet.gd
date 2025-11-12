@tool
class_name CharacterSheet
extends PanelContainer

@export var character: Character : set = _set_character

@export var _character_profile: CharacterProfile :
	set(new_character_profile):
		_character_profile = new_character_profile
		if not _character_profile: return
		_update()

@export_group("Configuration")
@export var _portrait: TextureRect
@export var _name: RichTextLabel
@export var _title: RichTextLabel
@export var _attributes: CharacterAttributesPanel
@export var _breath_dice: BreathDiceSelectionButtons
@export var _ability_labels: AbilityLabels

func _update() -> void:
	name = _character_profile.name
	_portrait.texture = _character_profile.portrait
	_name.text = _character_profile.name
	_title.text = _character_profile.get_title()
	_ability_labels.update_abilities(_character_profile.origins)

func _set_character(new_character: Character) -> void:
	if new_character == character: return
	if character != null:
		character.character_profile_changed.disconnect(_on_character_profile_changed)
		character.attribute_scores_changed.disconnect(_attributes.update_attributes)
		character.breath_dice_changed.disconnect(_breath_dice.setup_breath_dice)
		character.save_requested.disconnect(_breath_dice.update_dice_request)
		character.save_rolled.disconnect(_breath_dice.update_save_result)
		character.fight_requested.disconnect(_breath_dice.update_dice_request)
		character.fight_rolled.disconnect(_breath_dice.update_fight_result)
	character = new_character
	_character_profile = character.character_profile
	character.character_profile_changed.connect(_on_character_profile_changed)
	character.attribute_scores_changed.connect(_attributes.update_attributes)
	character.breath_dice_changed.connect(_breath_dice.setup_breath_dice)
	character.save_requested.connect(_breath_dice.update_dice_request)
	character.save_rolled.connect(_breath_dice.update_save_result)
	character.fight_requested.connect(_breath_dice.update_dice_request)
	character.fight_rolled.connect(_breath_dice.update_fight_result)
	_attributes.update_attributes(character)
	_breath_dice.setup_breath_dice(character.breath_dice)

func _on_character_profile_changed(character_profile: CharacterProfile) -> void:
	_character_profile = character_profile

func _on_save_dialog_file_selected(path: String) -> void:
	ResourceSaver.save(character.character_profile, path, ResourceSaver.FLAG_CHANGE_PATH)

func _on_load_dialog_file_selected(path: String) -> void:
	character.character_profile = ResourceLoader.load(path, "CharacterProfile")
