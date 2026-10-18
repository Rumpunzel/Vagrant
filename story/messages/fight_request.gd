class_name FightRequest
extends DiceRequest

signal selected_weapon_dice_changed(weapon_dice: Array[WeaponDie])

var selected_weapon_dice: Array[WeaponDie] :
	set(new_selected_weapon_dice):
		selected_weapon_dice = new_selected_weapon_dice
		selected_weapon_dice_changed.emit(selected_weapon_dice)

## The monster this exchange is fought against
var opponent: Monster
var fleeing: bool = false
## Foe attribute to impair when threatening with Nerves
var nerves_target: CharacterAttribute

func _init(for_character: Character, source: AdventureFightDecision, new_selected_weapon_dice: Array[WeaponDie] = []) -> void:
	super(for_character, for_character.get_favored_attribute(), source)
	if new_selected_weapon_dice.is_empty():
		for die_type: DieType in for_character.character_profile.weapon_dice: new_selected_weapon_dice.append(WeaponDie.new(die_type))
	selected_weapon_dice = new_selected_weapon_dice

func get_source() -> AdventureFightDecision: return _source

## What the player answers to: the opponent's threat (shown instead of the decision's text)
func get_description() -> String:
	if not opponent: return super()
	if fleeing: return "You look for a way to escape the %s." % opponent.get_monster_name()
	return "The %s threatens you with %s." % [opponent.get_monster_name(), Fight.describe_attribute(opponent.get_nature())]

## Only fighting back with a weapon offers a stance choice
func has_stance_choice() -> bool: return not fleeing and not selected_weapon_dice.is_empty()
func set_nerves_target(character_attribute: CharacterAttribute) -> void: nerves_target = character_attribute

func get_stance_description(for_attribute: CharacterAttribute) -> String:
	return get_source().stance_descriptions.get(for_attribute, for_attribute.fight_stance.description)

func _create_result() -> FightResult:
	assert(character)
	character.most_recently_chosen_attribute = attribute
	return FightResult.new(self)
