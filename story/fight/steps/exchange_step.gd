@abstract
class_name ExchangeStep
extends Resource

## One step of an exchange, for one side; the order is authored in [ExchangeSteps].
## Steps are shared resources: everything they work on comes from the [Fight] passed in.

enum ExchangeSide {
	PLAYER,
	MONSTER,
}

@export var side: ExchangeSide = ExchangeSide.PLAYER

## Applies this part of the exchange and returns what to tell about it
@abstract func enter(fight: Fight) -> String
## Checked once the step before it was entered; steps that don't apply are skipped
func applies(_fight: Fight) -> bool: return true

func is_player() -> bool: return side == ExchangeSide.PLAYER
func get_side(fight: Fight) -> FightSide: return fight.get_last_exchange().first if is_player() else fight.get_last_exchange().second
func get_foe_side(fight: Fight) -> FightSide: return fight.get_last_exchange().second if is_player() else fight.get_last_exchange().first
## "You" / "The Lurker"
func get_subject(fight: Fight) -> String: return "You" if is_player() else "The %s" % fight.monster.get_monster_name()
## "your" / "the Lurker's"
func get_owner(fight: Fight) -> String: return "your" if is_player() else "the %s's" % fight.monster.get_monster_name()
func get_foe_owner(fight: Fight) -> String: return "the %s's" % fight.monster.get_monster_name() if is_player() else "your"
func get_weapon(fight: Fight) -> Weapon: return fight.player_weapon if is_player() else fight.opponent_weapon
func get_foe_weapon(fight: Fight) -> Weapon: return fight.opponent_weapon if is_player() else fight.player_weapon
func get_shield(fight: Fight) -> Shield: return fight.player_shield if is_player() else fight.opponent_shield
## The character or monster this step is for
func get_actor(fight: Fight) -> Actor: return fight.protagonist if is_player() else fight.monster
## [param player_text] or [param monster_text], whichever side this step is for
func pick(player_text: String, monster_text: String) -> String: return player_text if is_player() else monster_text

## Marks [param face] on [param equipment] and returns the line telling it, "" if nothing was marked
static func _mark(equipment: Equipment, face: int, owner: String) -> String:
	if not equipment or not equipment.is_usable(): return ""
	var marked: int = equipment.mark(face)
	if marked == 0: return "%s %s is ruined." % [owner.capitalize(), equipment.get_equipment_name()]
	return "A %d is marked on %s %s." % [marked, owner, equipment.get_equipment_name()]

static func _join(lines: Array[String]) -> String:
	return " ".join(lines.filter(func(line: String) -> bool: return not line.is_empty()))
