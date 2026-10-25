class_name Fight
extends RefCounted

## One fight between two actors, across exchanges: in the story the protagonist (the player) against a monster,
## in the Fight Lab any two characters or monsters. Outcomes are told from the first actor's side.

enum Outcome {
	ONGOING,
	WON,
	LOST,
	DRAW,
	FLED,
}

## The steps every exchange goes through, phase by phase
var exchange_steps: ExchangeSteps = load("uid://yydyqypkbn0y")  # exchange_steps.tres
var decision: AdventureFightDecision
## [member FightExchange.first]'s actor
var first: Actor
var second: Actor
## The actor whose choices the story asks the player for (always [member first]); null: both decide by themselves
var player: Actor
var outcome: Outcome = Outcome.ONGOING
var exchanges: Array[FightExchange] = []
## Who failed the Guts save after an injury that left a score at 0 or below; ends the fight for them like running out of breath
var incapacitated: Dictionary[Actor, bool] = {}
## Rolls the incapacitation saves of actors that decide by themselves; replaceable for fixed dice in tests
var roll_dice: Callable = DiceRoller.roll_dice

## Which of the player's pieces takes each blocked foe die, as the player picked it
var armor_picks: Dictionary[Die, ArmorPick] = {}
## The player wants to pick the weapon die even when none needs forcing (several weapon dice)
var always_choose_weapon_die: bool = false

var _steps: Array[ExchangeStep] = exchange_steps.get_steps()
var _step_index: int = -1
var _paragraphs: Array[String] = []

func _init(for_decision: AdventureFightDecision, first_actor: Actor, second_actor: Actor, with_player: Actor = null) -> void:
	assert(for_decision and first_actor and second_actor)
	assert(not with_player or with_player == first_actor, "The player fights as the first actor")
	decision = for_decision
	first = first_actor
	second = second_actor
	player = with_player
	for actor: Actor in [first, second]: actor.prepare_for_fight()
	if first.is_out_of_breath(): outcome = Outcome.LOST

## The player's request for the next exchange; only in the story, where the player's character fights a monster
func create_request(fleeing: bool = false) -> FightRequest:
	assert(is_ongoing() and player is Character and second is Monster)
	var monster: Monster = second
	var request: FightRequest = FightRequest.new(player as Character, decision)
	request.opponent = monster
	request.fleeing = fleeing
	# Same as the resolver enforces
	if fleeing: request.attribute = Rules.AGILITY
	elif not request.selected_weapon: request.attribute = Rules.STRENGTH
	request.nerves_target = monster.get_attack().get_stance()
	request.always_choose_weapon_die = always_choose_weapon_die
	return request

## Applies the whole exchange at once; [method start_exchange], [method advance] and [method end_exchange] apply it step by step.
## The player's incapacitation save is left unresolved this way.
func resolve(result: FightResult) -> void:
	start_exchange_from(result)
	_apply_remaining_steps()

func start_exchange_from(result: FightResult) -> void:
	assert(result.get_dice_request().opponent == second)
	always_choose_weapon_die = result.get_dice_request().always_choose_weapon_die
	start_exchange(result.exchange)

func apply_exchange(exchange: FightExchange) -> void:
	start_exchange(exchange)
	_apply_remaining_steps()

## Records the exchange without applying anything yet
func start_exchange(exchange: FightExchange) -> void:
	assert(is_ongoing() and not is_exchange_pending())
	exchanges.append(exchange)
	armor_picks.clear()
	_paragraphs.clear()
	_find_step(0)

func is_exchange_pending() -> bool: return _step_index >= 0

## The step [method advance] enters next
func get_current_step() -> ExchangeStep:
	assert(is_exchange_pending())
	return _steps[_step_index]

## Enters the next step of the started exchange and returns what it told (also added to the summary)
func advance() -> String:
	var told: String = get_current_step().enter(self)
	tell(told)
	_find_step(_step_index + 1)
	return told

## Resolves the exchange being applied again after [param change] (taking the first actor's [FightSide]) set what they chose,
## e.g. the weapon die to strike with and whether to raise the shield.
## Only for parts not applied yet: it keeps the dice rolled and what was told.
func resolve_player_choice(change: Callable) -> void:
	var exchange: FightExchange = get_last_exchange()
	var player_side: FightSide = exchange.first.copy_inputs()
	change.call(player_side)
	exchanges[-1] = FightExchange.new(player_side, exchange.second.copy_inputs())

## Adds [param paragraph] to the exchange summary
func tell(paragraph: String) -> void:
	if not paragraph.is_empty(): _paragraphs.append(paragraph)

func get_paragraph_count() -> int: return _paragraphs.size()

## The first step from [param from_index] on that applies; -1 when none is left
func _find_step(from_index: int) -> void:
	for index: int in range(from_index, _steps.size()):
		if _steps[index].applies(self):
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
	if outcome == Outcome.WON and second is Monster: (second as Monster).incapacitated = true
	if not is_ongoing():
		for actor: Actor in [first, second]: actor.pick_up_dropped_gear()
	var line: String = ""
	# A loser who collapsed on the save was told so already
	match outcome:
		Outcome.WON:
			if not incapacitated.get(second, false): line = "%s can no longer resist." % capitalize_first(Fight.describe_actor(second, player))
		Outcome.LOST:
			if not incapacitated.get(first, false): line = "%s %s out of breath and can no longer resist." % [capitalize_first(Fight.describe_actor(first, player)), "are" if first == player else "is"]
		Outcome.DRAW: line = "Neither of you can go on." if player else "Neither of them can go on."
		Outcome.FLED: line = "%s %s away from %s." % [capitalize_first(Fight.describe_actor(first, player)), "get" if first == player else "gets", Fight.describe_actor(second, player)]
	tell(line)
	return line

func _evaluate_outcome() -> Outcome:
	var first_incapacitated: bool = incapacitated.get(first, false)
	var first_fled: bool = get_last_exchange().first.fleeing
	# Collapsing while running away still lets the foe have you
	if first_fled and first_incapacitated: return Outcome.LOST
	# Checked before breath: running out of breath only matters for facing the next exchange
	if first_fled: return Outcome.FLED
	var first_out: bool = _is_out(first)
	var second_out: bool = _is_out(second)
	if first_out and second_out: return Outcome.DRAW
	if first_out: return Outcome.LOST
	if second_out: return Outcome.WON
	return Outcome.ONGOING

func _is_out(actor: Actor) -> bool:
	if incapacitated.get(actor, false) or actor.is_out_of_breath(): return true
	return actor is Monster and (actor as Monster).incapacitated

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

## How the monster the player fights looks; only in the story
func get_condition_description() -> String:
	assert(second is Monster)
	var monster: Monster = second
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

## "you" for [param player], else "the Lurker", "Dorian"
static func describe_actor(actor: Actor, player_actor: Actor) -> String: return "you" if actor == player_actor else actor.get_reference()

## Upper-cases only the first letter (unlike [method String.capitalize])
static func capitalize_first(text: String) -> String: return text.left(1).to_upper() + text.substr(1)

static func describe_attribute(attribute: CharacterAttribute) -> String:
	return "[color=%s]%s[/color]" % [attribute.color.to_html(), attribute.descriptor]

static func _get_total(dice: Dictionary[DieType, int]) -> int:
	var total: int = 0
	for amount: int in dice.values(): total += amount
	return total
