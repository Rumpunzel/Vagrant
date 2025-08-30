class_name CharacterSheet
extends PanelContainer

@export var character: Character :
	set(new_character):
		if new_character == character: return
		if character != null:
			character.character_profile_changed.disconnect(_on_character_profile_changed)
			character.attribute_scores_changed.disconnect(_attributes.update_attributes)
			character.hit_dice_changed.disconnect(_hit_dice.update_hit_dice)
		character = new_character
		character.character_profile_changed.connect(_on_character_profile_changed)
		character.attribute_scores_changed.connect(_attributes.update_attributes)
		character.hit_dice_changed.connect(_hit_dice.update_hit_dice)
		_update()
		_attributes.update_attributes(character)
		_hit_dice.update_hit_dice(character.hit_dice)

@export_group("Configuration")
@export var _portrait: TextureRect
@export var _name: RichTextLabel
@export var _title: RichTextLabel
@export var _attributes: CharacterAttributesPanel
@export var _hit_dice: HitDiceSelectionButtons
@export var _ability_labels: AbilityLabels

func _update() -> void:
	name = character.name
	_portrait.texture = character.portrait
	_name.text = character.name
	_title.text = character.character_profile.get_title()
	_ability_labels.update_abilities(character.character_profile.origins)

func _on_character_profile_changed(_character_profile: CharacterProfile) -> void:
	_update()

func _on_save_dialog_file_selected(path: String) -> void:
	ResourceSaver.save(character.character_profile, path, ResourceSaver.FLAG_CHANGE_PATH)

func _on_load_dialog_file_selected(path: String) -> void:
	character.character_profile = ResourceLoader.load(path, "CharacterProfile")
