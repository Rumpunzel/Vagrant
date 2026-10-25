class_name FightRequest
extends DiceRequest

signal selected_weapon_changed(weapon: Weapon)

## Weapon picked for this exchange; null = fighting unarmed
var selected_weapon: Weapon : set = set_selected_weapon

var opponent: Monster
var fleeing: bool = false
## Pick the weapon die after the roll even when none needs forcing
var always_choose_weapon_die: bool = false
## Foe attribute to impair when threatening with Nerves
var nerves_target: CharacterAttribute

func _init(for_character: Character, source: AdventureFightDecision) -> void:
	super(for_character, for_character.get_favored_attribute(), source)
	selected_weapon = Weapon.get_first_usable(for_character.weapons)

func get_source() -> AdventureFightDecision: return _source

## What the player answers to: the opponent's threat (shown instead of the decision's text)
func get_description() -> String:
	if not opponent: return super()
	if fleeing: return "You look for a way to escape the %s." % opponent.get_monster_name()
	var attack: MonsterAttack = opponent.get_attack()
	var threat: String = "The %s threatens you with %s" % [opponent.get_monster_name(), Fight.describe_attribute(attack.get_stance())]
	if attack.get_nerves_target(): threat += ", aiming at your %s" % Fight.describe_attribute(attack.get_nerves_target())
	return threat + "."

func has_stance_choice() -> bool: return not fleeing and selected_weapon != null

func set_selected_weapon(weapon: Weapon) -> void:
	assert(not weapon or (weapon.is_usable() and character.weapons.has(weapon)))
	selected_weapon = weapon
	if not selected_weapon and not fleeing and attribute != Rules.STRENGTH: attribute = Rules.STRENGTH
	selected_weapon_changed.emit(selected_weapon)
func set_nerves_target(character_attribute: CharacterAttribute) -> void: nerves_target = character_attribute

func get_stance_description(for_attribute: CharacterAttribute) -> String:
	return get_source().stance_descriptions.get(for_attribute, for_attribute.fight_stance.description)

## What the player chose for this exchange
func get_plan() -> FightPlan:
	var plan: FightPlan = FightPlan.new(character, attribute, selected_breath_dice)
	plan.nerves_target = nerves_target
	plan.weapon = selected_weapon
	plan.fleeing = fleeing
	return plan

func _create_result() -> FightResult:
	assert(character)
	character.most_recently_chosen_attribute = attribute
	return FightResult.new(self)
