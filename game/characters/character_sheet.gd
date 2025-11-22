@tool
class_name CharacterSheet
extends CharacterPanel

@export_group("Configuration")
@export var _name: RichTextLabel
@export var _title: RichTextLabel
@export var _attributes: CharacterAttributesPanel
@export var _breath_dice: BreathDiceSelectionButtons
@export var _ability_labels: AbilityLabels

func profile_update() -> void:
	super.profile_update()
	_name.text = _character_profile.name
	_title.text = _character_profile.get_formatted_title()
	_ability_labels.update_abilities(_character_profile.origins)

func update_dice_request(dice_request: DiceRequest) -> void:
	_breath_dice.update_dice_request(dice_request)

func _get_breath_dice() -> BreathDice: return _breath_dice

func _set_character(new_character: Character) -> void:
	assert(new_character)
	if new_character == character: return
	super._set_character(new_character)
	_attributes.character = character

func _on_save_dialog_file_selected(path: String) -> void:
	ResourceSaver.save(character.character_profile, path, ResourceSaver.FLAG_CHANGE_PATH)

func _on_load_dialog_file_selected(path: String) -> void:
	character.character_profile = ResourceLoader.load(path, "CharacterProfile")
