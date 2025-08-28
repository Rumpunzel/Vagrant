@tool
class_name CharacterCreation
extends MarginContainer

signal character_created(characterprofile: CharacterProfile)

enum CreationStage {
	ATTRIBUTES,
	ORIGINS,
	DONE,
}

@export var _backgrounds: Array[Texture2D]

@export_group("Configuration")
@export var _stage: Stage
@export var _attributes_roller: AttributesRoller
@export var _origins_picker: OriginsPicker
@export var _inventory: Inventory
@export var _bio_editor: BioEditor
@export var _continue: Button
@export var _character_confirmation: CharacterConfirmation

var _creation_stage: CreationStage = CreationStage.ATTRIBUTES

var _name: String
var _portrait: Texture2D
var _attribute_scores: Dictionary[CharacterAttribute, AttributeScore]
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

func _on_attributes_rolled(attribute_scores: Dictionary[CharacterAttribute, AttributeScore]) -> void:
	_attribute_scores = attribute_scores
	var doubles_rolled: int = 0
	for attribute_score: AttributeScore in _attribute_scores.values():
		if attribute_score.get_type() == AttributeScore.Type.DOUBLE: doubles_rolled += 1
	_origins_picker.setup(doubles_rolled)
	_activate_continue()

func _on_origins_picked(origins: Array[Origin]) -> void:
	_origins = origins
	_activate_continue()

func _on_origins_unpicked() -> void:
	_origins = []
	_deactivate_continue()

func _on_details_changed(character_name: String, portrait: Texture2D) -> void:
	_name = character_name
	_portrait = portrait
	_character_confirmation.set_character_name(_name)

func _on_character_confirmed(character_name: String) -> void:
	_name = character_name
	var character_profile: CharacterProfile = CharacterProfile.new(_name, _portrait, _attribute_scores)
	character_created.emit(character_profile)
	Characters.create_character(character_profile)
	get_tree().change_scene_to_file("res://story/adventure.tscn")

func _on_continue_pressed() -> void:
	match _creation_stage:
		CreationStage.ATTRIBUTES:
			_creation_stage = _creation_stage + 1 as CreationStage
			_attributes_roller.collapse()
			_origins_picker.appear()
			_inventory.appear()
			_bio_editor.appear()
			_deactivate_continue()
		CreationStage.ORIGINS:
			_creation_stage = _creation_stage + 1 as CreationStage
			_character_confirmation.popup_centered()
		CreationStage.DONE: _character_confirmation.popup_centered()
		_: assert(false, "CreationStage %s not supported!" % _creation_stage)

func _on_background_timer_timeout() -> void:
	if _backgrounds.is_empty(): return
	_stage.background = _backgrounds.pick_random()
