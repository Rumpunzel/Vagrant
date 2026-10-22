class_name Monster
extends Actor

const UNARMED_ATTACK: MonsterAttack = preload("uid://c4a0yss3o6pxw")  # guts_attack.tres

@export var monster_profile: MonsterProfile :
	set(new_monster_profile):
		assert(new_monster_profile)
		monster_profile = new_monster_profile
		weapons = Weapon.carry(monster_profile.weapons, monster_profile.equipment_modifiers)
		armor = Armor.carry(monster_profile.armor, monster_profile.equipment_modifiers)
		shields = Shield.carry(monster_profile.shields, monster_profile.equipment_modifiers)
		recover_breath()

@export var spawned_from: AdventurePage

## Lost a fight or failed the Guts save after an injury that left a score at 0 or below; stays out of every fight from then on
var incapacitated: bool = false
var dead: bool = false

func recover_breath() -> void:
	breath_dice = monster_profile.get_breath_dice()

func get_monster_name() -> String: return monster_profile.name
func can_fight() -> bool: return not incapacitated and not dead
## Unarmed, a monster threatens with Guts like anyone else
func get_attack() -> MonsterAttack: return monster_profile.attack if has_natural_weapons() or get_weapon() else UNARMED_ATTACK

func get_score(attribute: CharacterAttribute) -> int:
	var score: int = monster_profile.attribute_scores[attribute]
	for injury: Injury in _injuries: score -= injury.magnitude
	return score

func has_natural_weapons() -> bool: return monster_profile.weapons.is_empty()

func get_weapon() -> Weapon: return Weapon.get_first_usable(weapons)
