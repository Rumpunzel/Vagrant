class_name SaveRequest
extends Resource

signal attribute_changed(attribute: CharacterAttribute)
signal selected_breath_dice_changed(selected_breath_dice: Array[BreathDie])

@export var description: String
@export var character_profile: CharacterProfile
@export var attribute: CharacterAttribute :
	set(new_attribute):
		attribute = new_attribute
		attribute_changed.emit(attribute)
@export var difficulty: int
@export var selected_breath_dice: Array[BreathDie] :
	set(new_selected_breath_dice):
		selected_breath_dice = new_selected_breath_dice
		selected_breath_dice_changed.emit(selected_breath_dice)

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
	var save_request: SaveRequest = SaveRequest.new(
		new_description,
		for_character.character_profile,
		with_attribute,
		new_difficulty,
		for_character.get_available_breath_dice().filter(_is_breath_die_auto_selected.bind(for_character.get_attribute_score(with_attribute))),
	)
	for_character.save_requested.emit(save_request)
	return save_request

static func _is_breath_die_auto_selected(die: BreathDie, attribute_score: AttributeScore) -> bool:
	return attribute_score.get_score() >= die.die_type.faces

func select_breath_die(breath_die: BreathDie) -> void:
	if selected_breath_dice.has(breath_die): return
	selected_breath_dice.append(breath_die)
	selected_breath_dice.sort_custom(func(first_die: BreathDie, second_die: BreathDie) -> bool: return first_die.die_type.faces < second_die.die_type.faces)
	selected_breath_dice_changed.emit(selected_breath_dice)

func deselect_breath_die(breath_die: BreathDie) -> void:
	selected_breath_dice.erase(breath_die)
	selected_breath_dice_changed.emit(selected_breath_dice)

func roll_save(character_resolver: Callable) -> SaveResult:
	var character: Character = character_resolver.call(character_profile)
	var attribute_score: AttributeScore = character.get_attribute_score(attribute)
	for die: BreathDie in selected_breath_dice: die.roll_save(attribute_score.get_score())
	var save_result: SaveResult = SaveResult.new(self)
	character.save_rolled.emit(save_result)
	character.continue_with_new_breath_dice()
	return save_result

func selected_breath_die_as_dice() -> Array[Die]:
	var dice_snapshot: Array[Die] = []
	dice_snapshot.assign(selected_breath_dice)
	return dice_snapshot
