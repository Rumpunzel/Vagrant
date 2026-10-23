@tool
class_name FightLabStrategy
extends Resource

## How the simulated player fights in the Fight Lab: one fixed policy, followed in every exchange

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
## Flee once this many breath dice or fewer are left; 0: never
@export_range(0, 15) var flee_at_breath_dice: int = 0
## Give in instead of rolling the incapacitation save, which is otherwise rolled all in
@export var gives_in: bool = false
## How the player commits and picks armour; none: never forcing, sparing armour
@export var weapon_tactic: WeaponTactic
@export var shield_tactic: ShieldTactic
@export var armor_tactic: ArmorTactic
