@tool
class_name CharacterCreation
extends VBoxContainer

signal character_created(character_profile: CharacterProfile)

enum CreationStage {
	ATTRIBUTES,
	ORIGINS,
	DONE,
}

@export_group("Configuration")
@export var _attributes_roller: AttributesRoller
@export var _origins_picker: OriginsPicker
@export var _inventory: Inventory
@export var _bio_editor: BioEditor
@export var _continue: Button
@export var _character_confirmation: CharacterConfirmation

var _creation_stage: CreationStage = CreationStage.ATTRIBUTES

var _name: String
var _title: String
var _portrait: Texture2D
var _attribute_scores: Dictionary[CharacterAttribute, BaseAttributeScore]
var _origins: Array[Origin] = []

func _ready() -> void:
	if Engine.is_editor_hint(): return
	_origins_picker.visible = false
	_inventory.visible = false
	_bio_editor.visible = false
	_deactivate_continue()
	_attributes_roller.setup()

func _activate_continue() -> void:
	_continue.disabled = false
	_continue.focus_mode = Control.FOCUS_ALL
	_continue.grab_focus()

func _deactivate_continue() -> void:
	_continue.disabled = true
	_continue.focus_mode = Control.FOCUS_NONE

func _get_attribute_modifiers() -> Array[AttributeScore.Modifier]:
	var modifiers: Array[AttributeScore.Modifier] = []
	for origin: Origin in _origins:
		modifiers.append_array(origin.get_attribute_score_modifiers())
	return modifiers

func _on_attributes_rolled(attribute_scores: Dictionary[CharacterAttribute, BaseAttributeScore]) -> void:
	_attribute_scores = attribute_scores
	_activate_continue()

func _on_origins_picked(origins: Array[Origin]) -> void:
	_origins = origins
	_attributes_roller.update_modifiers(_get_attribute_modifiers())
	_activate_continue()

func _on_origins_unpicked() -> void:
	_origins = []
	_attributes_roller.update_modifiers(_get_attribute_modifiers())
	_deactivate_continue()

func _on_details_changed(character_name: String, character_title: String, portrait: Texture2D) -> void:
	_name = character_name
	_title = character_title
	_portrait = portrait
	_character_confirmation.set_character_name(_name)

func _on_character_confirmed(character_name: String) -> void:
	_name = character_name
	var character_profile: CharacterProfile = CharacterProfile.new(_name, _title, _portrait, _attribute_scores, _origins)
	character_created.emit(character_profile)

func _on_continue_pressed() -> void:
	match _creation_stage:
		CreationStage.ATTRIBUTES:
			_creation_stage = _creation_stage + 1 as CreationStage
			var doubles_rolled: int = 0
			for attribute_score: BaseAttributeScore in _attribute_scores.values():
				if attribute_score.get_type() == AttributeScore.Type.DOUBLE: doubles_rolled += 1
			_origins_picker.setup(doubles_rolled)
			_attributes_roller.collapse()
			_origins_picker.appear()
			_inventory.appear()
			_bio_editor.appear()
		CreationStage.ORIGINS:
			_creation_stage = _creation_stage + 1 as CreationStage
			_character_confirmation.confirm()
		CreationStage.DONE: _character_confirmation.confirm()
		_: assert(false, "CreationStage %s not supported!" % _creation_stage)
