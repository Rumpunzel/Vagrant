class_name FightLabSimulator
extends RefCounted

## Plays whole fights through the game's own [Fight] between two actors that both decide by themselves:
## characters as their [FightLabStrategy] says, monsters as their profile says. Records are from side A's view.

const OUTCOMES: Dictionary[Fight.Outcome, String] = {
	Fight.Outcome.ONGOING: "unfinished",
	Fight.Outcome.WON: "won",
	Fight.Outcome.LOST: "lost",
	Fight.Outcome.DRAW: "draw",
	Fight.Outcome.FLED: "fled",
}

## Actors are nodes and need a parent while they fight
var _parent: Node

func _init(parent: Node) -> void:
	assert(parent)
	_parent = parent

## One fight from full breath and fresh gear: outcome, exchanges, damage, breath spent and left, and what happened to side A's gear.
## With [param with_log], "log" holds one entry per exchange: what was told, both threats, breath dice and injuries after it.
func simulate(matchup: FightLabMatchup, max_exchanges: int, with_log: bool = false) -> Dictionary[String, Variant]:
	var actor_a: Actor = _create_actor(matchup.profile_a)
	var actor_b: Actor = _create_actor(matchup.profile_b)
	var gear_before: Dictionary[String, int] = _count_gear(actor_a)
	var breath_start: int = actor_a.get_breath_dice_count()
	var exchange_log: Array[Dictionary] = []
	var fight: Fight = Fight.new(AdventureFightDecision.new(), actor_a, actor_b)
	var dealt: int = 0
	var taken: int = 0
	var weapon_dropped: bool = false
	var shield_dropped: bool = false
	while fight.is_ongoing() and fight.get_exchange_count() < max_exchanges:
		fight.apply_exchange(FightExchange.new(_plan(actor_a, matchup.strategy_a, true).roll(), _plan(actor_b, matchup.strategy_b, false).roll()))
		var exchange: FightExchange = fight.get_last_exchange()
		dealt += exchange.second.injury_taken
		taken += exchange.first.injury_taken
		weapon_dropped = weapon_dropped or exchange.first.weapon_dropped
		shield_dropped = shield_dropped or exchange.first.shield_dropped
		if with_log: exchange_log.append(_log_entry(fight, actor_a, actor_b))
	var record: Dictionary[String, Variant] = {
		"outcome": OUTCOMES[fight.outcome],
		"exchanges": fight.get_exchange_count(),
		"dealt": dealt,
		"taken": taken,
		"breath_left": actor_a.get_breath_dice_count(),
		"breath_spent": breath_start - actor_a.get_breath_dice_count(),
		"foe_breath_left": actor_b.get_breath_dice_count(),
		"weapon_dropped": weapon_dropped,
		"shield_dropped": shield_dropped,
	}
	var gear_after: Dictionary[String, int] = _count_gear(actor_a)
	for key: String in gear_after: record[key] = gear_after[key] - gear_before[key]
	if with_log: record["log"] = exchange_log
	actor_a.free()
	actor_b.free()
	return record

func _create_actor(profile: ActorProfile) -> Actor:
	var actor: Actor = profile.get_actor_scene().instantiate()
	_parent.add_child(actor)
	actor.set_profile(profile)
	return actor

## Characters fight by [param strategy], monsters by their profile
static func _plan(actor: Actor, strategy: FightLabStrategy, may_flee: bool) -> FightPlan:
	if actor is Monster: return (actor as Monster).get_fight_plan()
	return strategy.plan(actor as Character, may_flee)

static func _log_entry(fight: Fight, actor_a: Actor, actor_b: Actor) -> Dictionary:
	var exchange: FightExchange = fight.get_last_exchange()
	return {
		"text": fight.get_exchange_summary(),
		"threat": exchange.first.threat,
		"foe_threat": exchange.second.threat,
		"breath": actor_a.get_breath_dice_count(),
		"foe_breath": actor_b.get_breath_dice_count(),
		"injuries": actor_a.get_injury_total(),
		"foe_injuries": actor_b.get_injury_total(),
	}

## Marks and ruined pieces per kind of gear
static func _count_gear(actor: Actor) -> Dictionary[String, int]:
	var counts: Dictionary[String, int] = {}
	_count(counts, "weapon", actor.weapons)
	_count(counts, "shield", actor.shields)
	_count(counts, "armor", actor.armor)
	return counts

static func _count(counts: Dictionary[String, int], kind: String, equipment: Array) -> void:
	counts[kind + "_marks"] = 0
	counts[kind + "_ruined"] = 0
	for piece: Equipment in equipment:
		counts[kind + "_marks"] += piece.marked_faces.size()
		counts[kind + "_ruined"] += int(piece.ruined)
