@tool
class_name CharacterSheet
extends CharacterPanel

@export_group("Configuration")
@export var _name: RichTextLabel
@export var _title: RichTextLabel
@export var _attributes: CharacterAttributesPanel
@export var _ability_labels: AbilityLabels

func _ready() -> void:
	if Engine.is_editor_hint(): return
	visible = character != null

func _update() -> void:
	super._update()
	_name.text = _character_profile.name
	_title.text = _character_profile.get_title()
	_ability_labels.update_abilities(_character_profile.origins)

func _set_character(new_character: Character) -> void:
	assert(new_character)
	if character != null:
		character.attribute_scores_changed.disconnect(_attributes.update_attributes)
	super._set_character(new_character)
	character.attribute_scores_changed.connect(_attributes.update_attributes)
	_attributes.update_attributes(character)

func _on_close_pressed() -> void:
	hide()

func _on_pop_out_pressed() -> void:
	pass # Replace with function body.

func _on_character_selected(selected_character: Character, source: Control) -> void:
	if not selected_character:
		hide()
		return
	character = selected_character
	global_position.x = source.global_position.x
	show()

func _on_save_dialog_file_selected(path: String) -> void:
	ResourceSaver.save(character.character_profile, path, ResourceSaver.FLAG_CHANGE_PATH)

func _on_load_dialog_file_selected(path: String) -> void:
	character.character_profile = ResourceLoader.load(path, "CharacterProfile")
