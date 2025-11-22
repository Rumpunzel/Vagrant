@tool
@abstract
class_name CharacterPanel
extends PanelContainer

@export var character: Character : set = _set_character

@export var _character_profile: CharacterProfile :
	set(new_character_profile):
		_character_profile = new_character_profile
		if not _character_profile: return
		profile_update()

@export_placeholder("Character") var _name_suffix: String

@export_group("Configuration")
@export var _portrait: TextureRect

func profile_update() -> void:
	name = "%s - %s" % [_character_profile.name, _name_suffix]
	_update_portrait()

func character_update() -> void:
	_update_exhaustion()

func _update_portrait() -> void:
	_portrait.texture = _character_profile.portrait

func _update_exhaustion() -> void:
	_get_breath_dice().set_exhaustion(character.exhaustion)

@abstract func _get_breath_dice() -> BreathDice

func _set_character(new_character: Character) -> void:
	assert(new_character)
	if new_character == character: return
	if character != null:
		character.character_profile_changed.disconnect(_on_character_profile_changed)
		character.exhaustion_changed.disconnect(_on_exhaustion_changed)
	character = new_character
	_character_profile = character.character_profile
	character.character_profile_changed.connect(_on_character_profile_changed)
	character.exhaustion_changed.connect(_on_exhaustion_changed)
	if not is_node_ready(): await ready
	_get_breath_dice().character = character
	character_update()

func _on_character_profile_changed(character_profile: CharacterProfile) -> void:
	_character_profile = character_profile

func _on_exhaustion_changed(exhaustion: Array[DieType]) -> void:
	assert(character.exhaustion == exhaustion)
	_update_exhaustion()
