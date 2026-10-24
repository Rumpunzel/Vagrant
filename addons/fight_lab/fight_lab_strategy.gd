@tool
class_name FightLabStrategy
extends Resource

## How a character fights in the Fight Lab: one fixed policy, followed in every exchange. Monsters fight as their profile says.

enum BreathDiceChoice {
	## The dice the game selects for the stance by default (at least the smallest one)
	AUTO,
	ALL_IN,
}

## Stance while armed; none: the character's favoured attribute
@export var stance: CharacterAttribute
## Foe attribute to impair when threatening with Nerves; none: Guts
@export var nerves_target: CharacterAttribute
@export var breath_dice: BreathDiceChoice = BreathDiceChoice.AUTO
## Flee once this many breath dice or fewer are left; 0: never. Only on the first side, whose outcome the lab tells
@export_range(0, 15) var flee_at_breath_dice: int = 0
## How the character commits and picks armour; none: never forcing, sparing armour. The incapacitation save is rolled all in.
@export var weapon_tactic: WeaponTactic
@export var shield_tactic: ShieldTactic
@export var armor_tactic: ArmorTactic

## The character's next exchange, as this strategy fights it; [param may_flee] for the first side
func plan(character: Character, may_flee: bool) -> FightPlan:
	var fleeing: bool = may_flee and flee_at_breath_dice > 0 and character.get_breath_dice_count() <= flee_at_breath_dice
	var weapon: Weapon = Weapon.get_first_usable(character.weapons)
	# As the game enforces it: Blood to flee, Guts unarmed
	var attribute: CharacterAttribute = stance if stance else character.get_favored_attribute()
	if fleeing: attribute = Rules.AGILITY
	elif not weapon: attribute = Rules.STRENGTH
	var fight_plan: FightPlan = FightPlan.new(character, attribute, _select_breath_dice(character, attribute))
	fight_plan.fleeing = fleeing
	fight_plan.weapon = weapon
	fight_plan.nerves_target = nerves_target if nerves_target else Rules.STRENGTH
	fight_plan.weapon_tactic = weapon_tactic
	fight_plan.shield_tactic = shield_tactic
	fight_plan.armor_tactic = armor_tactic
	return fight_plan

func _select_breath_dice(character: Character, attribute: CharacterAttribute) -> Dictionary[DieType, int]:
	if breath_dice == BreathDiceChoice.ALL_IN: return character.breath_dice.duplicate()
	var selected: Dictionary[DieType, int] = character.get_auto_selected_breath_dice(attribute)
	if selected.values().any(func(amount: int) -> bool: return amount > 0): return selected
	var smallest: DieType = null
	for die_type: DieType in character.breath_dice:
		if character.breath_dice[die_type] > 0 and (not smallest or die_type.faces < smallest.faces): smallest = die_type
	return {smallest: 1}
