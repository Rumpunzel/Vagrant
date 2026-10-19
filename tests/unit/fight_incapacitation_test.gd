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
	_apply_until(Fight.Step.PLAYER_INJURY)
	assert_bool(_fight.player_must_resist_incapacitation()).is_true()

func test_no_save_without_an_injury() -> void:
	_character.suffer_injury(Injury.new(7))
	_start_exchange_unhurt()
	_apply_until(Fight.Step.PLAYER_INJURY)
	assert_bool(_fight.player_must_resist_incapacitation()).is_false()

func test_collapsing_while_fleeing_loses() -> void:
	_character.suffer_injury(Injury.new(5))
	_start_exchange_hurting_the_player(true)
	_apply_until(Fight.Step.PLAYER_INJURY)
	assert_bool(_fight.player_must_resist_incapacitation()).is_true()
	_fight.resist_player_incapacitation(false)
	_apply_until(Fight.Step.OUTCOME)
	assert_int(_fight.outcome).is_equal(Fight.Outcome.LOST)

func test_staying_conscious_while_fleeing_gets_away() -> void:
	_character.suffer_injury(Injury.new(5))
	_start_exchange_hurting_the_player(true)
	_apply_until(Fight.Step.PLAYER_INJURY)
	_fight.resist_player_incapacitation(true)
	_apply_until(Fight.Step.OUTCOME)
	assert_int(_fight.outcome).is_equal(Fight.Outcome.FLED)

func test_failed_save_loses_the_fight() -> void:
	_character.suffer_injury(Injury.new(5))
	_start_exchange_hurting_the_player(false)
	_apply_until(Fight.Step.PLAYER_INJURY)
	assert_str(_fight.resist_player_incapacitation(false)).is_equal("Everything goes dark.")
	_apply_until(Fight.Step.OUTCOME)
	assert_int(_fight.outcome).is_equal(Fight.Outcome.LOST)
	assert_str(_fight.get_exchange_summary()).contains("Everything goes dark.")
	assert_str(_fight.get_exchange_summary()).contains("You sink to the ground")

func test_passed_save_fights_on() -> void:
	_character.suffer_injury(Injury.new(5))
	_start_exchange_hurting_the_player(false)
	_apply_until(Fight.Step.PLAYER_INJURY)
	assert_str(_fight.resist_player_incapacitation(true)).is_equal("You keep your senses.")
	_apply_until(Fight.Step.OUTCOME)
	assert_bool(_fight.player_incapacitated).is_false()
	assert_str(_fight.get_exchange_summary(_fight.get_paragraph_count() - 1)).is_not_empty()

func test_monster_collapses_when_its_save_fails() -> void:
	_fight.roll_dice = func(_pool: Array[Die]) -> Array[Die]: return FightTestDice.dice([Rules.d8, Rules.d8], [4, 1])
	# Guts 5 - 3 - 3 = -1: overwhelmed, the save is against 6
	_monster.suffer_injury(Injury.new(3))
	_start_exchange_hurting_the_monster()
	_apply_until(Fight.Step.OUTCOME)
	assert_bool(_fight.monster_incapacitated).is_true()
	assert_int(_fight.outcome).is_equal(Fight.Outcome.WON)
	assert_str(_fight.get_exchange_summary()).contains("save against 6 — 4. It collapses.")

func test_monster_keeps_its_feet_when_its_save_passes() -> void:
	_fight.roll_dice = func(_pool: Array[Die]) -> Array[Die]: return FightTestDice.dice([Rules.d8], [6])
	_monster.suffer_injury(Injury.new(3))
	_start_exchange_hurting_the_monster()
	_apply_until(Fight.Step.MONSTER_INJURY)
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

func _apply_until(last_step: Fight.Step) -> void:
	for step: int in Fight.Step.values():
		if step > last_step: return
		if step >= _fight._next_step: _fight.apply_step(step as Fight.Step)
