extends GdUnitTestSuite

## Incapacitation: an injury that leaves a score at 0 or below calls for a Guts save against all injuries.

const GUTS: CharacterAttribute = Rules.STRENGTH

var _character: Character
var _monster: Monster
var _fight: Fight

func before_test() -> void:
	_character = auto_free(load("uid://bl0pdxri24fnh").instantiate())  # character.tscn
	add_child(_character)
	_character.character_profile = TestCharacters.adventurer()
	_monster = auto_free(load("uid://kmifqq0ejuri").instantiate())  # monster.tscn
	add_child(_monster)
	_monster.monster_profile = TestMonsters.cutthroat()
	_fight = Fight.new(AdventureFightDecision.new(), _character, _monster)

func test_overwhelmed_once_a_score_reaches_zero() -> void:
	# Guts, Blood and Nerves 7
	_character.suffer_injury(Injury.new(6))
	assert_bool(_character.is_overwhelmed_by_injuries()).is_false()
	_character.suffer_injury(Injury.new(1))
	assert_bool(_character.is_overwhelmed_by_injuries()).is_true()
	# The cutthroat's Guts 5 is its lowest score
	_monster.suffer_injury(Injury.new(5))
	assert_bool(_monster.is_overwhelmed_by_injuries()).is_true()

func test_player_must_resist_after_an_injury_that_overwhelms() -> void:
	_character.suffer_injury(Injury.new(5))
	_start_exchange_hurting_the_player(false)
	assert_object(_advance_to(IncapacitationStep, ExchangeStep.Side.PLAYER)).is_not_null()

func test_no_save_without_an_injury() -> void:
	_character.suffer_injury(Injury.new(7))
	_start_exchange_unhurt()
	assert_object(_advance_to(IncapacitationStep, ExchangeStep.Side.PLAYER)).is_null()

func test_collapsing_while_fleeing_loses() -> void:
	_character.suffer_injury(Injury.new(5))
	_start_exchange_hurting_the_player(true)
	var save: IncapacitationStep = _advance_to(IncapacitationStep, ExchangeStep.Side.PLAYER)
	assert_object(save).is_not_null()
	save.resolve(_fight, false)
	_advance_to(OutcomeStep, ExchangeStep.Side.PLAYER)
	assert_int(_fight.outcome).is_equal(Fight.Outcome.LOST)

func test_staying_conscious_while_fleeing_gets_away() -> void:
	_character.suffer_injury(Injury.new(5))
	_start_exchange_hurting_the_player(true)
	(_advance_to(IncapacitationStep, ExchangeStep.Side.PLAYER) as IncapacitationStep).resolve(_fight, true)
	_advance_to(OutcomeStep, ExchangeStep.Side.PLAYER)
	assert_int(_fight.outcome).is_equal(Fight.Outcome.FLED)

func test_failed_save_loses_the_fight() -> void:
	_character.suffer_injury(Injury.new(5))
	_start_exchange_hurting_the_player(false)
	var save: IncapacitationStep = _advance_to(IncapacitationStep, ExchangeStep.Side.PLAYER)
	assert_int(save.get_difficulty(_fight)).is_equal(8)
	assert_str(save.resolve(_fight, false)).is_equal("Everything goes dark.")
	_advance_to(OutcomeStep, ExchangeStep.Side.PLAYER)
	assert_int(_fight.outcome).is_equal(Fight.Outcome.LOST)
	assert_str(_fight.get_exchange_summary()).contains("Everything goes dark.")
	assert_str(_fight.get_exchange_summary()).contains("You sink to the ground")

func test_passed_save_fights_on() -> void:
	_character.suffer_injury(Injury.new(5))
	_start_exchange_hurting_the_player(false)
	assert_str((_advance_to(IncapacitationStep, ExchangeStep.Side.PLAYER) as IncapacitationStep).resolve(_fight, true)).is_equal("You keep your senses.")
	_advance_to(OutcomeStep, ExchangeStep.Side.PLAYER)
	assert_bool(_fight.player_incapacitated).is_false()
	assert_str(_fight.get_exchange_summary(_fight.get_paragraph_count() - 1)).is_not_empty()

func test_monster_collapses_when_its_save_fails() -> void:
	_fight.roll_dice = func(_pool: Array[Die]) -> Array[Die]: return FightTestDice.dice([Rules.d8, Rules.d8], [4, 1])
	# Guts 5 - 3 - 3 = -1: overwhelmed, the save is against 6
	_monster.suffer_injury(Injury.new(3))
	_start_exchange_hurting_the_monster()
	_advance_to(OutcomeStep, ExchangeStep.Side.PLAYER)
	assert_bool(_fight.monster_incapacitated).is_true()
	assert_int(_fight.outcome).is_equal(Fight.Outcome.WON)
	assert_str(_fight.get_exchange_summary()).contains("save against 6 — 4. It collapses.")

func test_monster_keeps_its_feet_when_its_save_passes() -> void:
	_fight.roll_dice = func(_pool: Array[Die]) -> Array[Die]: return FightTestDice.dice([Rules.d8], [6])
	_monster.suffer_injury(Injury.new(3))
	_start_exchange_hurting_the_monster()
	_advance_to(OutcomeStep, ExchangeStep.Side.PLAYER)
	assert_bool(_fight.monster_incapacitated).is_false()
	assert_str(_fight.get_exchange_summary()).contains("save against 6 — 6. It keeps its feet.")

## 1 vs 4, unarmed: the player takes 3
func _start_exchange_hurting_the_player(fleeing: bool) -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(7), [], fleeing)
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [4]), FightTestDice.scores(7))
	_fight.start_exchange(FightExchange.new(player, opponent), player.lost_breath_dice)

## 4 vs 1: the player wins, the unarmed foe deals nothing
func _start_exchange_unhurt() -> void:
	var player: FightSide = FightSide.new(Rules.AGILITY, FightTestDice.dice([Rules.d4], [4]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d4, 1))
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [1]), FightTestDice.scores(7))
	_fight.start_exchange(FightExchange.new(player, opponent), player.lost_breath_dice)

## 4 vs 1, unarmed: the monster takes 3
func _start_exchange_hurting_the_monster() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [4]), FightTestDice.scores(7))
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [1]), FightTestDice.scores(7))
	_fight.start_exchange(FightExchange.new(player, opponent), player.lost_breath_dice)

## Advances until the next step is a [param step_class] for [param side] and returns it without entering it
## (or, for the outcome, after entering it); null if the exchange ended without one
func _advance_to(step_class: Script, side: ExchangeStep.Side) -> ExchangeStep:
	while _fight.is_exchange_pending():
		var step: ExchangeStep = _fight.get_current_step()
		if is_instance_of(step, step_class) and (step.side == side or step is OutcomeStep):
			if step is OutcomeStep: _fight.advance()
			return step
		_fight.advance()
	return null
