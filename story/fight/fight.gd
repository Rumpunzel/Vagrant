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

## The parts of an exchange in the order they are applied and shown
enum Step {
	DICE,
	UNNERVING,
	CONSEQUENCES,
	ARMOR,
	PLAYER_INJURY,
	MONSTER_INJURY,
	OUTCOME,
}

var decision: AdventureFightDecision
var protagonist: Character
var monster: Monster
var outcome: Outcome = Outcome.ONGOING
var exchanges: Array[FightExchange] = []
## Failed the Guts save after an injury that left a score at 0 or below; ends the fight like running out of breath
var player_incapacitated: bool = false
var monster_incapacitated: bool = false
## Rolls the monster's incapacitation save; replaceable for fixed dice in tests
var roll_dice: Callable = DiceRoller.roll_dice

var _player_lost_breath_dice: Array[Die] = []
var _player_weapon: Weapon
var _opponent_weapon: Weapon
var _next_step: int = Step.size()
var _equipment_marks: Array[String] = []
var _paragraphs: Array[String] = []

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
	request.nerves_target = monster.get_attack().get_stance()
	return request

## Applies the whole exchange at once; [method start_exchange] and [method apply_step] apply it step by step
func resolve(result: FightResult) -> void:
	start_exchange_from(result)
	_apply_remaining_steps()

func start_exchange_from(result: FightResult) -> void:
	assert(result.get_dice_request().opponent == monster)
	start_exchange(result.exchange, result.get_lost_breath_dice(), result.get_dice_request().selected_weapon, result.opponent_weapon)

## [param player_lost_breath_dice] may differ from the exchange's raw losses (origins).
func apply_exchange(exchange: FightExchange, player_lost_breath_dice: Array[Die], player_weapon: Weapon = null, opponent_weapon: Weapon = null) -> void:
	start_exchange(exchange, player_lost_breath_dice, player_weapon, opponent_weapon)
	_apply_remaining_steps()

## Records the exchange without applying anything yet
func start_exchange(exchange: FightExchange, player_lost_breath_dice: Array[Die], player_weapon: Weapon = null, opponent_weapon: Weapon = null) -> void:
	assert(is_ongoing() and not is_exchange_pending())
	exchanges.append(exchange)
	_player_lost_breath_dice = player_lost_breath_dice
	_player_weapon = player_weapon
	_opponent_weapon = opponent_weapon
	_paragraphs.clear()
	_next_step = 0

func is_exchange_pending() -> bool: return _next_step < Step.size()

## Applies [param step] of the started exchange (steps go in order) and returns what to tell about it, "" for nothing
func apply_step(step: Step) -> String:
	assert(step == _next_step, "Fight steps must be applied in order")
	_next_step += 1
	var player: FightSide = get_last_exchange().first
	var opponent: FightSide = get_last_exchange().second
	var monster_name: String = monster.get_monster_name()
	var monster_owner: String = "the %s's" % monster_name
	var lines: Array[String] = []
	_equipment_marks.clear()
	match step:
		Step.DICE:
			lines.append(_describe_dice(player, opponent))
		Step.UNNERVING:
			if not player.impairments.is_empty(): lines.append("The %s unnerves you (%s)." % [monster_name, _describe_impairments(player.impairments)])
			if not opponent.impairments.is_empty(): lines.append("You unnerve the %s (%s)." % [monster_name, _describe_impairments(opponent.impairments)])
		Step.CONSEQUENCES:
			protagonist.lose_breath_dice(_player_lost_breath_dice)
			monster.lose_breath_dice(opponent.lost_breath_dice)
			if not player.failed_weapon_dice.is_empty(): lines.append("You fail to wield your weapon.")
			if not opponent.failed_weapon_dice.is_empty(): lines.append("The %s fails to wield its weapon." % monster_name)
			for failed_die: Die in player.failed_weapon_dice: _mark(_player_weapon, failed_die.result, "your")
			for failed_die: Die in opponent.failed_weapon_dice: _mark(_opponent_weapon, failed_die.result, monster_owner)
			lines.append_array(_equipment_marks)
			if not _player_lost_breath_dice.is_empty(): lines.append("You lose %d breath %s." % [_player_lost_breath_dice.size(), "die" if _player_lost_breath_dice.size() == 1 else "dice"])
			if not opponent.lost_breath_dice.is_empty(): lines.append("The %s loses %d breath %s." % [monster_name, opponent.lost_breath_dice.size(), "die" if opponent.lost_breath_dice.size() == 1 else "dice"])
		Step.ARMOR:
			_strike_armor(player, _player_weapon, "your", monster.armor, monster_owner)
			_strike_armor(opponent, _opponent_weapon, monster_owner, protagonist.armor, "your")
			lines.append_array(_equipment_marks)
			if opponent.damage_prevented > 0: lines.append("The %s's armour takes %d off your blow." % [monster_name, opponent.damage_prevented])
			if player.damage_prevented > 0: lines.append("Your armour takes %d off the %s's blow." % [player.damage_prevented, monster_name])
		Step.PLAYER_INJURY:
			if player.injury_taken > 0: protagonist.suffer_injury(Injury.new(player.injury_taken))
		Step.MONSTER_INJURY:
			if opponent.injury_taken > 0:
				monster.suffer_injury(Injury.new(opponent.injury_taken))
				if monster.is_overwhelmed_by_injuries(): lines.append(_resist_monster_incapacitation())
			# Injuries have their own display; only an exchange without any gets a line
			elif player.injury_taken == 0: lines.append("Neither of you is hurt.")
		Step.OUTCOME:
			outcome = _evaluate_outcome(player.fleeing)
			var outcome_line: String = _describe_outcome()
			if not outcome_line.is_empty(): lines.append(outcome_line)
	var paragraph: String = " ".join(lines)
	if not paragraph.is_empty(): _paragraphs.append(paragraph)
	return paragraph

## After [constant Step.PLAYER_INJURY]: the player has to make a Guts save against all their injuries (see [method resist_player_incapacitation])
func player_must_resist_incapacitation() -> bool:
	var player: FightSide = get_last_exchange().first
	return player.injury_taken > 0 and protagonist.is_overwhelmed_by_injuries()

## The outcome of the player's incapacitation save; returns its line, which also joins the exchange summary
func resist_player_incapacitation(success: bool) -> String:
	player_incapacitated = not success
	var line: String = "You keep your senses." if success else "Everything goes dark."
	_paragraphs.append(line)
	return line

func get_paragraph_count() -> int: return _paragraphs.size()

## Rolls all of the monster's breath dice as a Guts save against all its injuries
func _resist_monster_incapacitation() -> String:
	var difficulty: int = monster.get_injury_total()
	var dice: Array[Die] = []
	dice.assign(roll_dice.call(monster.get_breath_dice_pool()))
	var highest: int = FightExchange.get_highest_result(dice)
	var guts: int = monster.get_score(Rules.STRENGTH)
	var lost: Array[Die] = []
	lost.assign(dice.filter(func(die: Die) -> bool: return die.result > guts))
	monster.lose_breath_dice(lost)
	monster_incapacitated = highest < difficulty
	return "The %s can barely stand: %s save against %d — %d. %s" % [
		monster.get_monster_name(), describe_attribute(Rules.STRENGTH), difficulty, highest,
		"It collapses." if monster_incapacitated else "It keeps its feet.",
	]

func _apply_remaining_steps() -> void:
	while is_exchange_pending(): apply_step(_next_step as Step)

## Each blocked die marks the attacker's weapon and one random blocking piece of the defender's armour
func _strike_armor(attacker: FightSide, attacker_weapon: Weapon, attacker_owner: String, defender_armor: Array[Armor], defender_owner: String) -> void:
	for blocked_die: Die in attacker.blocked_weapon_dice:
		var blocking: Array[Armor] = []
		blocking.assign(defender_armor.filter(func(piece: Armor) -> bool: return piece.blocks(blocked_die.result)))
		if not blocking.is_empty():
			var piece: Armor = blocking.pick_random()
			_equipment_marks.append("%s %s blocks the %d." % [defender_owner.capitalize(), piece.get_equipment_name(), blocked_die.result])
			_mark(piece, blocked_die.result, defender_owner)
		_mark(attacker_weapon, blocked_die.result, attacker_owner)

func _mark(equipment: Equipment, face: int, owner: String) -> void:
	if not equipment or not equipment.is_usable(): return
	match equipment.mark(face):
		Equipment.Mark.MARKED: _equipment_marks.append("A %d is marked on %s %s." % [face, owner, equipment.get_equipment_name()])
		Equipment.Mark.RUINED: _equipment_marks.append("%s %s is ruined." % [owner.capitalize(), equipment.get_equipment_name()])

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
	if monster.get_score(monster.get_attack().get_stance()) <= 0: wounds = "grievously wounded"
	elif monster.get_injury_total() > 0: wounds = "bleeding"
	var breath_left: int = monster.get_breath_dice_count()
	var breath: String = "breathes steadily"
	if breath_left == 1: breath = "gasps for its last breath"
	elif breath_left < _get_total(monster.monster_profile.get_breath_dice()): breath = "is breathing hard"
	return "The %s is %s and %s." % [monster.get_monster_name(), wounds, breath]

## What has been told about the last exchange so far, one paragraph per step, from paragraph [param from] on
func get_exchange_summary(from: int = 0) -> String:
	var summary: String = ""
	for paragraph: String in _paragraphs.slice(from): summary += "[p]%s[/p]" % paragraph
	return summary

func _describe_outcome() -> String:
	match outcome:
		Outcome.WON: return "The %s can no longer resist." % monster.get_monster_name()
		Outcome.LOST: return "You sink to the ground and can no longer resist." if player_incapacitated else "You are out of breath and can no longer resist."
		Outcome.DRAW: return "Neither of you can go on."
		Outcome.FLED: return "You get away from the %s." % monster.get_monster_name()
	return ""

func _evaluate_outcome(player_fled: bool) -> Outcome:
	# Collapsing while running away still lets the foe have you
	if player_fled and player_incapacitated: return Outcome.LOST
	# Checked before breath: running out of breath only matters for facing the next exchange
	if player_fled: return Outcome.FLED
	var player_out: bool = player_incapacitated or _is_out_of_breath(protagonist.breath_dice)
	var monster_out: bool = monster_incapacitated or monster.is_out_of_breath()
	if player_out and monster_out: return Outcome.DRAW
	if player_out: return Outcome.LOST
	if monster_out: return Outcome.WON
	return Outcome.ONGOING

## "You threaten with Guts (4) and your Sword (3), the Lurker with Nerves (6) and its Knife (7)."
func _describe_dice(player: FightSide, opponent: FightSide) -> String:
	return "You %s with %s, the %s with %s." % [
		"flee" if player.fleeing else "threaten", _describe_side_dice(player, _player_weapon, "your"),
		monster.get_monster_name(), _describe_side_dice(opponent, _opponent_weapon, "its"),
	]

func _describe_side_dice(side: FightSide, weapon: Weapon, owner: String) -> String:
	var text: String = "%s (%d)" % [describe_attribute(side.stance), side.threat]
	if weapon and not side.weapon_dice.is_empty():
		var results: Array[String] = []
		for die: Die in side.weapon_dice: results.append(str(die.result))
		text += " and %s %s (%s)" % [owner, weapon.get_equipment_name(), ", ".join(results)]
	return text

static func _describe_impairments(impairments: Dictionary[CharacterAttribute, int]) -> String:
	var parts: Array[String] = []
	for attribute: CharacterAttribute in impairments: parts.append("−%d %s" % [impairments[attribute], describe_attribute(attribute)])
	return ", ".join(parts)

static func describe_attribute(attribute: CharacterAttribute) -> String:
	return "[color=%s]%s[/color]" % [attribute.color.to_html(), attribute.descriptor]

static func _get_total(dice: Dictionary[DieType, int]) -> int:
	var total: int = 0
	for amount: int in dice.values(): total += amount
	return total

static func _is_out_of_breath(breath_dice: Dictionary[DieType, int]) -> bool:
	for amount: int in breath_dice.values(): if amount > 0: return false
	return true
