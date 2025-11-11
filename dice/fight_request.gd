class_name FightRequest
extends DiceRequest

signal fight_rolled(fight_result: FightResult)
signal selected_weapon_dice_changed(weapon_dice: Array[WeaponDie])

var source: StoryFightDecision
var selected_weapon_dice: Array[WeaponDie] :
	set(new_sselected_weapon_dice):
		selected_weapon_dice = new_sselected_weapon_dice
		selected_weapon_dice_changed.emit(selected_weapon_dice)

func _init(for_character: Character, story_decision: StoryFightDecision) -> void:
	super(for_character, for_character.get_highest_attribute())
	source = story_decision
	for_character.request_fight(self)

func roll_fight() -> void:
	var attribute_score: AttributeScore = character.get_attribute_score(attribute)
	for die: BreathDie in selected_breath_dice: die.roll_save(attribute_score.get_score())
	var fight_result: FightResult = FightResult.new(self)
	fight_rolled.emit(fight_result)

func get_description() -> String:
	return source.description

func get_stance_description(for_attribute: CharacterAttribute) -> String:
	return source.stance_descriptions.get(for_attribute, for_attribute.stance_description)

func get_selected_dice() -> Array[Die]:
	var dice_snapshot: Array[Die] = []
	dice_snapshot.assign(selected_weapon_dice)
	return super.get_selected_dice() + dice_snapshot
