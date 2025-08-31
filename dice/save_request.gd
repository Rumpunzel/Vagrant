class_name SaveRequest
extends Resource

@export var description: String
@export var character_profile: CharacterProfile
@export var attribute: CharacterAttribute
@export var difficulty: int
@export var selected_breath_dice: Array[BreathDie]

func _init(
	new_description: String,
	for_character_profile: CharacterProfile,
	with_attribute: CharacterAttribute,
	new_difficulty: int,
	new_selected_breath_dice: Array[BreathDie],
) -> void:
	description = new_description
	character_profile = for_character_profile
	attribute = with_attribute
	difficulty = new_difficulty
	selected_breath_dice = new_selected_breath_dice

static func create(
	new_description: String,
	for_character: Character,
	with_attribute: CharacterAttribute,
	new_difficulty: int,
) -> SaveRequest:
	return SaveRequest.new(
		new_description,
		for_character.character_profile,
		with_attribute,
		new_difficulty,
		for_character.get_available_breath_dice().filter(_is_breath_die_auto_selected.bind(for_character.get_attribute_score(with_attribute))),
	)

static func _is_breath_die_auto_selected(die: BreathDie, attribute_score: AttributeScore) -> bool:
	return attribute_score.get_score() >= die.die_type.faces

func roll_save(character_resolver: Callable) -> SaveResult:
	var character: Character = character_resolver.call(character_profile)
	var attribute_score: AttributeScore = character.get_attribute_score(attribute)
	for die: BreathDie in selected_breath_dice: die.roll_save(attribute_score.get_score())
	return SaveResult.new(self)

func snapshot_dice() -> Array[Die]:
	var dice_snapshot: Array[Die] = []
	selected_breath_dice.assign(selected_breath_dice.map(func(die: BreathDie) -> Die: return die.duplicate()))
	dice_snapshot.assign(selected_breath_dice)
	return dice_snapshot
