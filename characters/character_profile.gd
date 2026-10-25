@tool
class_name CharacterProfile
extends ActorProfile

signal title_changed(title: String)
signal portrait_changed(portrait: Texture2D)
signal attribute_scores_changed(attribute_scores: Dictionary[CharacterAttribute, RolledAttributeScore])
signal origins_changed(origins: Array[Origin])

@export_placeholder("Title") var title: String:
	set(new_title):
		title = new_title
		title_changed.emit(title)

@export var portrait: Texture2D:
	set(new_portrait):
		portrait = new_portrait
		if portrait:
			var directory_path: String = portrait.resource_path.get_base_dir()
			if directory_path == _portrait_directory: return
			_portrait_directory = directory_path
		portrait_changed.emit(portrait)
@export_dir var _portrait_directory: String:
	set(new_portrait_directory):
		_portrait_directory = new_portrait_directory
		portrait = load(_portrait_directory.path_join(_portrait_file_name)) if _portrait_directory else null
		_additional_portraits.clear()
		if not _portrait_directory: return
		for portrait_file_name: String in _additional_portrait_file_names:
			_additional_portraits[portrait_file_name] = load(_portrait_directory.path_join(portrait_file_name))
@export var _additional_portraits: Dictionary[String, Texture2D]:
	set(new_additional_portraits):
		_additional_portraits = new_additional_portraits
		if _additional_portraits.is_empty(): return
		var first_additional_portrait: Texture2D = _additional_portraits.values().front()
		var directory_path: String = first_additional_portrait.resource_path.get_base_dir()
		if directory_path == _portrait_directory: return
		_portrait_directory = directory_path

@export var attribute_scores: Dictionary[CharacterAttribute, RolledAttributeScore] = {
	Rules.STRENGTH: null,
	Rules.AGILITY: null,
	Rules.INTELLIGENCE: null,
}:
	set(new_attribute_scores):
		attribute_scores = new_attribute_scores
		attribute_scores_changed.emit(attribute_scores)

@export var origins: Array[Origin] = [null, null]:
	set(new_origins):
		origins = new_origins
		origins_changed.emit(origins)

## Applied to every weapon when it is handed out, e.g. "battered"
@export var weapon_modifiers: Array[EquipmentModifier] = []
## Applied to every piece of armour when it is handed out
@export var armor_modifiers: Array[EquipmentModifier] = []
## Applied to every shield when it is handed out
@export var shield_modifiers: Array[EquipmentModifier] = []
## Item -> how many are carried
@export var items: Dictionary[ItemProfile, int] = {}

@export_group("Configuration")
@export var _portrait_file_name: String = "Fulllength.png"
@export var _additional_portrait_file_names: Array[String] = ["Medium.png", "Small.png"]

static func create(
	new_name: String,
	new_portrait: Texture2D,
	new_attribute_scores: Dictionary[CharacterAttribute, RolledAttributeScore],
	new_origins: Array[Origin],
	new_title: String,
) -> CharacterProfile:
	var character_profile: CharacterProfile = CharacterProfile.new()
	character_profile.name = new_name
	character_profile.portrait = new_portrait
	character_profile.attribute_scores = new_attribute_scores
	character_profile.origins = new_origins
	character_profile.title = new_title
	return character_profile

func is_valid() -> bool:
	return has_valid_attributes() and has_valid_origins() and has_valid_bio()

func has_valid_attributes() -> bool:
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		if not attribute_scores.has(attribute) or not attribute_scores.get(attribute): return false
	return true

func has_valid_origins() -> bool:
	if origins.size() != 2: return false
	for origin: Origin in origins: if not origin: return false
	return true

func has_valid_bio() -> bool:
	return not name.is_empty() and portrait

func get_formatted_title() -> String:
	return Origin.concatenate_with_icons(origins) if title.is_empty() else title

func get_portrait(identifier: String) -> Texture2D:
	return _additional_portraits.get(identifier, portrait)

func get_available_doubles() -> int:
	var doubles_rolled: int = 0
	for attribute_score: RolledAttributeScore in attribute_scores.values():
		if attribute_score and attribute_score.get_type() == AttributeScore.Type.DOUBLE: doubles_rolled += 1
	return doubles_rolled

func get_abilities() -> Array[Ability]:
	var abilities: Array[Ability] = []
	for origin: Origin in origins: if origin: abilities.append_array(origin.abilities)
	return abilities

func get_weapon_modifiers() -> Array[EquipmentModifier]: return weapon_modifiers
func get_armor_modifiers() -> Array[EquipmentModifier]: return armor_modifiers
func get_shield_modifiers() -> Array[EquipmentModifier]: return shield_modifiers

func get_attribute_score(attribute: CharacterAttribute) -> int:
	var rolled: RolledAttributeScore = attribute_scores.get(attribute)
	return rolled.get_score() if rolled else 0

## Rolled as two d6 adding up to [param score] (clamped to 2–12); origins still add to it
func with_attribute_score(attribute: CharacterAttribute, score: int) -> ActorProfile:
	var copy: CharacterProfile = duplicate()
	copy.attribute_scores = attribute_scores.duplicate()
	var first: int = clampi(floori(score / 2.0), 1, 6)
	# Not Rules.d6: Main reaches this script while Rules is still loading its die types
	var d6: DieType = load("uid://clrjpyohkfypv")  # d6.tres
	copy.attribute_scores[attribute] = RolledAttributeScore.new([Die.new(d6, first), Die.new(d6, clampi(score - first, 1, 6))] as Array[Die])
	return copy

func can_fight() -> bool: return has_valid_attributes()

func get_actor_scene() -> PackedScene: return load("uid://bl0pdxri24fnh")  # character.tscn

func get_attribute_modifiers() -> Array[AttributeScore.Modifier]:
	var modifiers: Array[AttributeScore.Modifier] = []
	for origin: Origin in origins:
		if not origin: continue
		modifiers.append_array(origin.get_attribute_score_modifiers())
	return modifiers
