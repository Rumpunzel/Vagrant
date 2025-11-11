class_name FightRequest
extends SaveRequest

@export var enemies: Array[MonsterProfile]

func _init(
	new_description: String,
	for_character_profile: CharacterProfile,
	for_enemies: Array[MonsterProfile],
	with_attribute: CharacterAttribute,
	new_difficulty: int,
	new_selected_breath_dice: Array[BreathDie],
) -> void:
	super(new_description, for_character_profile, with_attribute, new_difficulty, new_selected_breath_dice)
	enemies = for_enemies

static func create_fight_request(
	new_description: String,
	for_character: Character,
	for_enemies: Array[MonsterProfile],
) -> FightRequest:
	var highest_attribute: CharacterAttribute = for_character.get_highest_attribute()
	var enemey_threat: int = 5
	var fight_request: FightRequest = FightRequest.new(
		new_description,
		for_character.character_profile,
		for_enemies, highest_attribute,
		enemey_threat,
		for_character.get_available_breath_dice().filter(_is_breath_die_auto_selected.bind(for_character.get_attribute_score(highest_attribute))),
	)
	return fight_request
