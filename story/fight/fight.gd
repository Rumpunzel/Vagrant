class_name Fight
extends RefCounted

## One fight between the protagonist and a single monster, across exchanges.

enum Outcome {
	ONGOING,
	WON,
	LOST,
	DRAW,
	FLED,
}

var decision: AdventureFightDecision
var protagonist: Character
var monster: Monster
var outcome: Outcome = Outcome.ONGOING
var exchanges: Array[FightExchange] = []

var _last_equipment_marks: Array[String] = []

func _init(for_decision: AdventureFightDecision, for_protagonist: Character, against_monster: Monster) -> void:
	assert(for_decision and for_protagonist and against_monster)
	decision = for_decision
	protagonist = for_protagonist
	monster = against_monster
	monster.recover_breath()
	if _is_out_of_breath(protagonist.breath_dice): outcome = Outcome.LOST

func create_request(fleeing: bool = false) -> FightRequest:
	assert(is_ongoing())
	var request: FightRequest = FightRequest.new(protagonist, decision)
	request.opponent = monster
	request.fleeing = fleeing
	# Same as the resolver enforces
	if fleeing: request.attribute = Rules.AGILITY
	elif not request.selected_weapon: request.attribute = Rules.STRENGTH
	request.nerves_target = monster.get_nature()
	return request

func resolve(result: FightResult) -> void:
	assert(result.get_dice_request().opponent == monster)
	apply_exchange(result.exchange, result.get_lost_breath_dice(), result.get_dice_request().selected_weapon, result.opponent_weapon, result.player_shield, result.opponent_shield)

## [param player_lost_breath_dice] may differ from the exchange's raw losses (origins).
func apply_exchange(exchange: FightExchange, player_lost_breath_dice: Array[Die], player_weapon: Weapon = null, opponent_weapon: Weapon = null, player_shield: Shield = null, opponent_shield: Shield = null) -> void:
	assert(is_ongoing())
	exchanges.append(exchange)
	var player: FightSide = exchange.first
	var opponent: FightSide = exchange.second
	protagonist.lose_breath_dice(player_lost_breath_dice)
	monster.lose_breath_dice(opponent.lost_breath_dice)
	if player.injury_taken > 0: protagonist.suffer_injury(Injury.new(player.injury_taken))
	if opponent.injury_taken > 0: monster.suffer_injury(Injury.new(opponent.injury_taken))
	_last_equipment_marks.clear()
	var monster_owner: String = "the %s's" % monster.get_monster_name()
	for failed_die: Die in player.failed_weapon_dice: _mark(player_weapon, failed_die.result, "your")
	for failed_die: Die in opponent.failed_weapon_dice: _mark(opponent_weapon, failed_die.result, monster_owner)
	for failed_die: Die in player.failed_shield_dice: _mark(player_shield, failed_die.result, "your")
	for failed_die: Die in opponent.failed_shield_dice: _mark(opponent_shield, failed_die.result, monster_owner)
	_strike_armor(player, player_weapon, "your", monster.armor, monster_owner)
	_strike_armor(opponent, opponent_weapon, monster_owner, protagonist.armor, "your")
	outcome = _evaluate_outcome(player.fleeing)

## Each blocked die marks the attacker's weapon and one random blocking piece of the defender's armour
func _strike_armor(attacker: FightSide, attacker_weapon: Weapon, attacker_owner: String, defender_armor: Array[Armor], defender_owner: String) -> void:
	for blocked_die: Die in attacker.blocked_weapon_dice:
		var blocking: Array[Armor] = []
		blocking.assign(defender_armor.filter(func(piece: Armor) -> bool: return piece.blocks(blocked_die.result)))
		if not blocking.is_empty():
			var piece: Armor = blocking.pick_random()
			_last_equipment_marks.append("%s %s blocks the %d." % [defender_owner.capitalize(), piece.get_equipment_name(), blocked_die.result])
			_mark(piece, blocked_die.result, defender_owner)
		_mark(attacker_weapon, blocked_die.result, attacker_owner)

func _mark(equipment: Equipment, face: int, owner: String) -> void:
	if not equipment or not equipment.is_usable(): return
	match equipment.mark(face):
		Equipment.Mark.MARKED: _last_equipment_marks.append("A %d is marked on %s %s." % [face, owner, equipment.get_equipment_name()])
		Equipment.Mark.RUINED: _last_equipment_marks.append("%s %s is ruined." % [owner.capitalize(), equipment.get_equipment_name()])

func is_ongoing() -> bool: return outcome == Outcome.ONGOING
func get_exchange_count() -> int: return exchanges.size()
func get_last_exchange() -> FightExchange: return exchanges.back() if not exchanges.is_empty() else null

func get_transition() -> AdventurePage:
	var page_reference: AdventurePageReference = null
	match outcome:
		Outcome.WON: page_reference = decision.transition
		Outcome.LOST: page_reference = decision.failure_transition
		Outcome.DRAW: page_reference = decision.draw_transition
		Outcome.FLED: page_reference = decision.flee_transition
		_: assert(false, "Fight is still ongoing")
	return page_reference.get_adventure_page() if page_reference else null

func get_consequences() -> Array[AdventureConsequence]:
	match outcome:
		Outcome.WON: return decision.consequences
		Outcome.LOST: return decision.failure_consequences
	return []

func get_title() -> String:
	return "%s — Exchange %d" % [monster.get_monster_name(), get_exchange_count() + 1]

func get_condition_description() -> String:
	var wounds: String = "unhurt"
	if monster.get_score(monster.get_nature()) <= 0: wounds = "grievously wounded"
	elif monster.get_injury_total() > 0: wounds = "bleeding"
	var breath_left: int = monster.get_breath_dice_count()
	var breath: String = "breathes steadily"
	if breath_left == 1: breath = "gasps for its last breath"
	elif breath_left < _get_total(monster.monster_profile.get_breath_dice()): breath = "is breathing hard"
	return "The %s is %s and %s." % [monster.get_monster_name(), wounds, breath]

## What happened in the last exchange, plus how the fight ended if it did
func get_exchange_summary() -> String:
	var summary: String = _describe_last_exchange()
	match outcome:
		Outcome.WON: summary += "[p]The %s can no longer resist.[/p]" % monster.get_monster_name()
		Outcome.LOST: summary += "[p]You are out of breath and can no longer resist.[/p]"
		Outcome.DRAW: summary += "[p]Neither of you can go on.[/p]"
		Outcome.FLED: summary += "[p]You get away from the %s.[/p]" % monster.get_monster_name()
	return summary

func _evaluate_outcome(player_fled: bool) -> Outcome:
	# Checked before breath: running out of breath only matters for facing the next exchange
	if player_fled: return Outcome.FLED
	var player_out: bool = _is_out_of_breath(protagonist.breath_dice)
	var monster_out: bool = monster.is_out_of_breath()
	if player_out and monster_out: return Outcome.DRAW
	if player_out: return Outcome.LOST
	if monster_out: return Outcome.WON
	return Outcome.ONGOING

func _describe_last_exchange() -> String:
	var exchange: FightExchange = get_last_exchange()
	if not exchange: return ""
	var player: FightSide = exchange.first
	var opponent: FightSide = exchange.second
	var monster_name: String = monster.get_monster_name()
	var lines: Array[String] = []
	lines.append("You %s with %s (%d), the %s with %s (%d)." % [
		"flee" if player.fleeing else "threaten", describe_attribute(player.stance), player.threat,
		monster_name, describe_attribute(opponent.stance), opponent.threat,
	])
	if not player.failed_weapon_dice.is_empty(): lines.append("You fail to wield your weapon.")
	if not opponent.failed_weapon_dice.is_empty(): lines.append("The %s fails to wield its weapon." % monster_name)
	if not player.failed_shield_dice.is_empty(): lines.append("You fail to raise your shield.")
	if not opponent.failed_shield_dice.is_empty(): lines.append("The %s fails to raise its shield." % monster_name)
	if player.shield_target: lines.append("Your shield takes %d off the %s's %d." % [player.shield_value, monster_name, player.shield_target.result])
	if opponent.shield_target: lines.append("The %s's shield takes %d off your %d." % [monster_name, opponent.shield_value, opponent.shield_target.result])
	lines.append_array(_last_equipment_marks)
	if not player.lost_breath_dice.is_empty(): lines.append("You lose %d breath %s." % [player.lost_breath_dice.size(), "die" if player.lost_breath_dice.size() == 1 else "dice"])
	if not opponent.lost_breath_dice.is_empty(): lines.append("The %s loses %d breath %s." % [monster_name, opponent.lost_breath_dice.size(), "die" if opponent.lost_breath_dice.size() == 1 else "dice"])
	if player.injury_taken == 0 and opponent.injury_taken == 0: lines.append("Neither of you is hurt.")
	return "[p]%s[/p]" % " ".join(lines)

static func describe_attribute(attribute: CharacterAttribute) -> String:
	return "[color=%s]%s[/color]" % [attribute.color.to_html(), attribute.descriptor]

static func _get_total(dice: Dictionary[DieType, int]) -> int:
	var total: int = 0
	for amount: int in dice.values(): total += amount
	return total

static func _is_out_of_breath(breath_dice: Dictionary[DieType, int]) -> bool:
	for amount: int in breath_dice.values(): if amount > 0: return false
	return true
