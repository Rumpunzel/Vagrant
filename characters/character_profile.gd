@tool
class_name CharacterProfile
extends Resource

@export_placeholder("Name") var name: String

@export var portrait: Texture2D :
	set(new_portrait):
		portrait = new_portrait
		if not portrait: return
		var directory_path: String = portrait.resource_path.get_base_dir()
		if directory_path == _portrait_directory: return
		_portrait_directory = directory_path

@export_dir var _portrait_directory: String :
	set(new_portrait_directory):
		_portrait_directory = new_portrait_directory
		portrait = load(_portrait_directory.path_join(_portrait_file_name)) if _portrait_directory else null
		_additional_portraits.clear()
		for portrait_file_name: String in _additional_portrait_file_names:
			_additional_portraits[portrait_file_name] = load(_portrait_directory.path_join(portrait_file_name))

@export var _additional_portraits: Dictionary[String, Texture2D] :
	set(new_additional_portraits):
		_additional_portraits = new_additional_portraits
		if _additional_portraits.is_empty(): return
		var first_additional_portrait: Texture2D = _additional_portraits.values().front()
		var directory_path: String = first_additional_portrait.resource_path.get_base_dir()
		if directory_path == _portrait_directory: return
		_portrait_directory = directory_path

@export var attribute_scores: Dictionary[CharacterAttribute, BaseAttributeScore] = {
	Rules.STRENGTH: null,
	Rules.AGILITY: null,
	Rules.INTELLIGENCE: null,
}

@export var origins: Array[Origin]

@export_placeholder("Title") var _title: String
@export var _breath_dice: Dictionary[DieType, int] = {
	Rules.d4: 1,
	Rules.d6: 1,
	Rules.d8: 1,
	Rules.d10: 1,
	Rules.d12: 1,
}

@export_group("Configuration")
@export var _portrait_file_name: String = "Fulllength.png"
@export var _additional_portrait_file_names: Array[String] = ["Medium.png", "Small.png"]

static func create(
	new_name: String,
	new_portrait: Texture2D,
	new_attribute_scores: Dictionary[CharacterAttribute, BaseAttributeScore],
	new_origins: Array[Origin],
	new_title: String,
) -> CharacterProfile:
	var character_profile: CharacterProfile = CharacterProfile.new()
	character_profile.name = new_name
	character_profile.portrait = new_portrait
	character_profile.attribute_scores = new_attribute_scores
	character_profile.origins = new_origins
	character_profile._title = new_title
	return character_profile

func get_attribute_scores() -> Dictionary[CharacterAttribute, AttributeScore]:
	var attibute_scores: Dictionary[CharacterAttribute, AttributeScore] = {}
	for attribute: CharacterAttribute in Rules.ATTRIBUTES:
		var modifiers: Array[AttributeScore.Modifier] = []
		for origin: Origin in origins:
			modifiers.append_array(origin.get_attribute_score_modifiers())
		attibute_scores[attribute] = AttributeScore.create_with_modifiers(attribute, attribute_scores[attribute], modifiers)
	assert(attibute_scores.size() == Rules.ATTRIBUTES.size())
	return attibute_scores

func get_breath_dice() -> Array[BreathDie]:
	return DiceRoller.generate_breath_dice_pool(_breath_dice)

func get_title() -> String:
	return Origin.concatenate_with_icons(origins) if _title.is_empty() else _title

func get_portrait(identifier: String) -> Texture2D:
	return _additional_portraits.get(identifier, portrait)
