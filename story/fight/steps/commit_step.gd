class_name CommitStep
extends ExchangeStep

## Where the player commits, right after the roll: the weapon die to strike with and whether to raise the shield.
## Shown and resolved by whoever presents the exchange, through [method Fight.resolve_player_choice].

func applies(fight: Fight) -> bool: return is_player(fight) and (has_weapon_choice(fight) or has_shield_choice(fight))

func enter(_fight: Fight) -> String: return ""

## Some weapon die needs forcing, or the player asked to pick among several
func has_weapon_choice(fight: Fight) -> bool:
	var weapon_side: FightSide = get_side(fight)
	var weapon: Weapon = get_weapon(fight)
	if not weapon or not weapon.is_usable() or weapon_side.has_natural_weapons: return false
	if fight.always_choose_weapon_die and weapon_side.weapon_dice.size() > 1: return true
	return weapon_side.weapon_dice.any(func(die: Die) -> bool: return not weapon_side.is_free_weapon_die(die))

func has_shield_choice(fight: Fight) -> bool:
	var shield: Shield = get_shield(fight)
	return shield and shield.is_usable() and not get_side(fight).shield_dice.is_empty()

## What the exchange would strike with if the player changed nothing
func get_default_weapon_die(fight: Fight) -> Die:
	var weapon_side: FightSide = get_side(fight)
	return weapon_side.usable_weapon_dice[0] if not weapon_side.usable_weapon_dice.is_empty() else null

## "Your Sword comes up 4 and 9. Your Buckler comes up 5."
func describe_roll(fight: Fight) -> String:
	var weapon_side: FightSide = get_side(fight)
	var lines: Array[String] = []
	if has_weapon_choice(fight):
		var results: Array[String] = []
		for die: Die in weapon_side.weapon_dice: results.append(str(die.result))
		lines.append("Your %s comes up %s." % [get_weapon(fight).get_equipment_name(), " and ".join(results)])
	if has_shield_choice(fight): lines.append("Your %s comes up %d." % [get_shield(fight).get_equipment_name(), weapon_side.shield_dice[0].result])
	return _join(lines)

static func describe_weapon_die(weapon_side: FightSide, die: Die) -> String:
	var overshoot: int = weapon_side.get_weapon_overshoot(die)
	if overshoot > 0: return "Force the %d: −%d threat, %s." % [die.result, overshoot, _describe_wear(weapon_side.weapon, die.result, overshoot)]
	if weapon_side.marked_faces.has(die.result): return "Force the marked %d: %s." % [die.result, _describe_wear(weapon_side.weapon, die.result, 1)]
	return "Strike with the %d." % die.result

## What forcing does to [param weapon]: "marks the 9 and 10 (6 of 8 faces left)", "marks the 8, then it is ruined"
static func _describe_wear(weapon: Weapon, face: int, times: int) -> String:
	var faces: Array[int] = weapon.preview_marks(face, times)
	var ruined: bool = faces.has(0)
	faces.erase(0)
	var marked: Array[String] = []
	for marked_face: int in faces: marked.append(str(marked_face))
	var text: String = "marks the %s" % " and ".join(marked) if not marked.is_empty() else ""
	if ruined: return "%s, then it is ruined" % text if not text.is_empty() else "it is ruined"
	return "%s (%d of %d faces left)" % [text, weapon.get_unmarked_count() - faces.size(), weapon.get_markable_faces().size()]

func describe_shield(fight: Fight) -> String:
	var shield_side: FightSide = get_side(fight)
	var shield_name: String = get_shield(fight).get_equipment_name()
	var overshoot: int = shield_side.get_shield_overshoot()
	if overshoot > 0: return "Force your %s up: −%d threat." % [shield_name, overshoot]
	return "Raise your %s." % shield_name
