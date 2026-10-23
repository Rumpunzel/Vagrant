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

## The steps every exchange goes through, in order
var exchange_steps: ExchangeSteps = load("uid://yydyqypkbn0y")  # exchange_steps.tres
var decision: AdventureFightDecision
var protagonist: Character
var monster: Monster
var outcome: Outcome = Outcome.ONGOING
var exchanges: Array[FightExchange] = []
## Failed the Guts save after an injury that left a score at 0 or below; ends the fight like running out of breath
var player_incapacitated: bool = false
## Rolls the monster's incapacitation save; replaceable for fixed dice in tests
var roll_dice: Callable = DiceRoller.roll_dice

## Of the exchange being applied; the player's lost breath dice may differ from the exchange's raw losses (origins)
var player_lost_breath_dice: Array[Die] = []
var player_weapon: Weapon
var opponent_weapon: Weapon
var player_shield: Shield
var opponent_shield: Shield
## Which of the player's pieces takes each blocked foe die, as the player picked it
var armor_picks: Dictionary[Die, ArmorPick] = {}
## The player wants to pick the weapon die even when none needs forcing (several weapon dice)
var always_choose_weapon_die: bool = false

var _step_index: int = -1
var _paragraphs: Array[String] = []

func _init(for_decision: AdventureFightDecision, for_protagonist: Character, against_monster: Monster) -> void:
	assert(for_decision and for_protagonist and against_monster)
	decision = for_decision
	protagonist = for_protagonist
	monster = against_monster
	monster.recover_breath()
	if protagonist.is_out_of_breath(): outcome = Outcome.LOST

func create_request(fleeing: bool = false) -> FightRequest:
	assert(is_ongoing())
	var request: FightRequest = FightRequest.new(protagonist, decision)
	request.opponent = monster
	request.fleeing = fleeing
	# Same as the resolver enforces
	if fleeing: request.attribute = Rules.AGILITY
	elif not request.selected_weapon: request.attribute = Rules.STRENGTH
	request.nerves_target = monster.get_attack().get_stance()
	request.always_choose_weapon_die = always_choose_weapon_die
	return request

## Applies the whole exchange at once; [method start_exchange], [method advance] and [method end_exchange] apply it step by step.
## An incapacitation save is left unresolved this way.
func resolve(result: FightResult) -> void:
	start_exchange_from(result)
	_apply_remaining_steps()

func start_exchange_from(result: FightResult) -> void:
	assert(result.get_dice_request().opponent == monster)
	always_choose_weapon_die = result.get_dice_request().always_choose_weapon_die
	start_exchange(result.exchange, result.get_lost_breath_dice(), result.get_dice_request().selected_weapon, result.opponent_weapon, result.player_shield, result.opponent_shield)

func apply_exchange(exchange: FightExchange, lost_breath_dice: Array[Die], with_player_weapon: Weapon = null, with_opponent_weapon: Weapon = null, with_player_shield: Shield = null, with_opponent_shield: Shield = null) -> void:
	start_exchange(exchange, lost_breath_dice, with_player_weapon, with_opponent_weapon, with_player_shield, with_opponent_shield)
	_apply_remaining_steps()

## Records the exchange without applying anything yet
func start_exchange(exchange: FightExchange, lost_breath_dice: Array[Die], with_player_weapon: Weapon = null, with_opponent_weapon: Weapon = null, with_player_shield: Shield = null, with_opponent_shield: Shield = null) -> void:
	assert(is_ongoing() and not is_exchange_pending())
	exchanges.append(exchange)
	player_lost_breath_dice = lost_breath_dice
	player_weapon = with_player_weapon
	opponent_weapon = with_opponent_weapon
	player_shield = with_player_shield
	opponent_shield = with_opponent_shield
	armor_picks.clear()
	_paragraphs.clear()
	_find_step(0)

func is_exchange_pending() -> bool: return _step_index >= 0

## The step [method advance] enters next
func get_current_step() -> ExchangeStep:
	assert(is_exchange_pending())
	return exchange_steps.steps[_step_index]

## Enters the next step of the started exchange and returns what it told (also added to the summary)
func advance() -> String:
	var told: String = get_current_step().enter(self)
	tell(told)
	_find_step(_step_index + 1)
	return told

## Resolves the exchange being applied again after [param change] (taking the player's [FightSide]) set what they chose,
## e.g. the weapon die to strike with and whether to raise the shield.
## Only for parts not applied yet: it keeps the dice rolled and what was told.
func resolve_player_choice(change: Callable) -> void:
	var exchange: FightExchange = get_last_exchange()
	var player: FightSide = exchange.first.copy_inputs()
	change.call(player)
	exchanges[-1] = FightExchange.new(player, exchange.second.copy_inputs())

## Adds [param paragraph] to the exchange summary
func tell(paragraph: String) -> void:
	if not paragraph.is_empty(): _paragraphs.append(paragraph)

func get_paragraph_count() -> int: return _paragraphs.size()

## The first step from [param from_index] on that applies; -1 when none is left
func _find_step(from_index: int) -> void:
	for index: int in range(from_index, exchange_steps.steps.size()):
		if exchange_steps.steps[index].applies(self):
			_step_index = index
			return
	_step_index = -1

func _apply_remaining_steps() -> void:
	while is_exchange_pending(): advance()
	end_exchange()

## Once every step was applied: decides how the fight stands and returns the line telling it, "" while it goes on
func end_exchange() -> String:
	assert(not is_exchange_pending())
	outcome = _evaluate_outcome()
	# A beaten monster stays down; whether it is spared is up to the story
	if outcome == Outcome.WON: monster.incapacitated = true
	if not is_ongoing():
		protagonist.pick_up_dropped_gear()
		monster.pick_up_dropped_gear()
	var line: String = ""
	match outcome:
		Outcome.WON: line = "The %s can no longer resist." % monster.get_monster_name()
		Outcome.LOST: line = "You sink to the ground and can no longer resist." if player_incapacitated else "You are out of breath and can no longer resist."
		Outcome.DRAW: line = "Neither of you can go on."
		Outcome.FLED: line = "You get away from the %s." % monster.get_monster_name()
	tell(line)
	return line

func _evaluate_outcome() -> Outcome:
	var player_fled: bool = get_last_exchange().first.fleeing
	# Collapsing while running away still lets the foe have you
	if player_fled and player_incapacitated: return Outcome.LOST
	# Checked before breath: running out of breath only matters for facing the next exchange
	if player_fled: return Outcome.FLED
	var player_out: bool = player_incapacitated or protagonist.is_out_of_breath()
	var monster_out: bool = monster.incapacitated or monster.is_out_of_breath()
	if player_out and monster_out: return Outcome.DRAW
	if player_out: return Outcome.LOST
	if monster_out: return Outcome.WON
	return Outcome.ONGOING

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

func get_title() -> String: return  ""

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

static func describe_attribute(attribute: CharacterAttribute) -> String:
	return "[color=%s]%s[/color]" % [attribute.color.to_html(), attribute.descriptor]

static func _get_total(dice: Dictionary[DieType, int]) -> int:
	var total: int = 0
	for amount: int in dice.values(): total += amount
	return total
