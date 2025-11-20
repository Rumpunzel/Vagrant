@tool
class_name CharacterCreation
extends Node

signal character_created(character_profile: CharacterProfile)

enum CreationStage {
	ATTRIBUTES,
	ORIGINS,
	DONE,
}

@export var character_profile: CharacterProfile:
	set(new_character_profile):
		assert(new_character_profile)
		if character_profile:
			character_profile.name_changed.disconnect(_on_name_changed)
		character_profile = new_character_profile
		_on_name_changed(character_profile.name)
		if is_node_ready(): _setup()
		character_profile.name_changed.connect(_on_name_changed)

@export_group("Configuration")
@export var _attributes_roller: AttributesRoller
@export var _origins_picker: OriginsPicker
@export var _inventory: Inventory
@export var _bio_editor: BioEditor
@export var _continue: Button
@export var _character_confirmation: CharacterConfirmation

var _creation_stage: CreationStage = CreationStage.ATTRIBUTES :
	set(new_creation_stage):
		_creation_stage = new_creation_stage
		match _creation_stage:
			CreationStage.ATTRIBUTES: pass
			CreationStage.ORIGINS:
				_origins_picker.setup(character_profile)
				_origins_picker.show()
				#_inventory.show()
				_bio_editor.setup(character_profile)
				_bio_editor.show()
			CreationStage.DONE: _character_confirmation.confirm()
			_: assert(false, "CreationStage %s not supported!" % _creation_stage)

func _ready() -> void:
	if Engine.is_editor_hint(): return
	_origins_picker.visible = false
	_inventory.visible = false
	_bio_editor.visible = false
	_deactivate_continue()
	if character_profile: _setup()

func _setup() -> void:
	_attributes_roller.setup(character_profile)
	if character_profile.has_valid_attributes():
		_creation_stage = CreationStage.ORIGINS
		_activate_continue()

func _activate_continue() -> void:
	_continue.disabled = false
	_continue.focus_mode = Control.FOCUS_ALL
	_continue.grab_focus()

func _deactivate_continue() -> void:
	_continue.disabled = true
	_continue.focus_mode = Control.FOCUS_NONE

func _on_attributes_rolled(attribute_scores: Dictionary[CharacterAttribute, BaseAttributeScore]) -> void:
	assert(character_profile.attribute_scores == attribute_scores)
	_activate_continue()

func _on_origins_picked(origins: Array[Origin]) -> void:
	assert(character_profile.origins == origins)
	_attributes_roller.update_modifiers(character_profile.get_attribute_modifiers())
	if origins.size() == 2: _activate_continue()
	else: _deactivate_continue()

func _on_name_changed(character_name: String) -> void:
	_character_confirmation.set_character_name(character_name)

func _on_continue_pressed() -> void:
	match _creation_stage:
		CreationStage.ATTRIBUTES: _creation_stage = CreationStage.ORIGINS
		CreationStage.ORIGINS: _creation_stage = CreationStage.DONE
		CreationStage.DONE: _character_confirmation.confirm()
		_: assert(false, "CreationStage %s not supported!" % _creation_stage)

func _on_character_confirmed(character_name: String) -> void:
	character_profile.name = character_name
	assert(character_profile.is_valid())
	character_created.emit(character_profile)
