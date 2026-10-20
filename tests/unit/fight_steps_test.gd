extends GdUnitTestSuite

## Exchange steps: each applies its part when entered, whatever order exchange_steps.tres puts them in.

const GUTS: CharacterAttribute = Rules.STRENGTH
var _side_steps: Array[Script] = [DiceStep, UnnervingStep, WeaponCheckStep, BreathDiceStep, ArmorStep, InjuryStep, IncapacitationStep]

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

func test_authored_order_has_every_step_once_per_side() -> void:
	var steps: Array[ExchangeStep] = _fight.exchange_steps.steps
	for step_class: Script in _side_steps:
		for side: ExchangeStep.ExchangeSide in [ExchangeStep.ExchangeSide.PLAYER, ExchangeStep.ExchangeSide.MONSTER]:
			var matching: Array = steps.filter(func(step: ExchangeStep) -> bool: return is_instance_of(step, step_class) and step.side == side)
			assert_int(matching.size()).override_failure_message("%s for side %d" % [step_class.get_global_name(), side]).is_equal(1)
	assert_int(steps.filter(func(step: ExchangeStep) -> bool: return step is TieStep).size()).is_equal(1)

func test_breath_dice_are_lost_before_the_incapacitation_save() -> void:
	# The save rolls the dice a side has left; losing the exchange's dice after it would count them twice
	var steps: Array[ExchangeStep] = _fight.exchange_steps.steps
	for side: ExchangeStep.ExchangeSide in [ExchangeStep.ExchangeSide.PLAYER, ExchangeStep.ExchangeSide.MONSTER]:
		var breath: int = steps.find_custom(func(step: ExchangeStep) -> bool: return step is BreathDiceStep and step.side == side)
		var save: int = steps.find_custom(func(step: ExchangeStep) -> bool: return step is IncapacitationStep and step.side == side)
		assert_int(breath).override_failure_message("breath dice step for side %d comes after its incapacitation step" % side).is_less(save)

func test_steps_apply_their_part_only_when_entered() -> void:
	# 9 vs 8: the player's 9 is lost (Guts 7), the monster's 8 and 7 too (Guts 5); unarmed, only the winner's vantage of 1 hurts
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 2, 2, 9]), FightTestDice.scores(7))
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([8, 7, 1]), FightTestDice.scores(5))
	_fight.start_exchange(FightExchange.new(player, opponent), player.lost_breath_dice)
	var entered: Array[String] = []
	while _fight.is_exchange_pending():
		var step: ExchangeStep = _fight.get_current_step()
		var player_dice: int = _character.get_breath_dice_count_for(Rules.d12)
		var monster_dice: int = _monster.breath_dice[Rules.d8]
		var monster_injury: int = _monster.get_injury_total()
		var told: String = _fight.advance()
		var player_breath_step: bool = step is BreathDiceStep and step.is_player()
		var monster_breath_step: bool = step is BreathDiceStep and not step.is_player()
		assert_int(_character.get_breath_dice_count_for(Rules.d12)).is_equal(player_dice - 1 if player_breath_step else player_dice)
		assert_int(_monster.breath_dice[Rules.d8]).is_equal(monster_dice - 2 if monster_breath_step else monster_dice)
		assert_int(_monster.get_injury_total()).is_equal(monster_injury + 1 if step is InjuryStep and not step.is_player() else monster_injury)
		if player_breath_step: assert_str(told).is_equal("You lose 1 breath die.")
		if monster_breath_step: assert_str(told).is_equal("The Cutthroat loses 2 breath dice.")
		entered.append("%s %d" % [step.get_script().get_global_name(), step.side])
	# The player is unhurt, nobody is overwhelmed and the threats differ: those steps are skipped
	assert_array(entered).not_contains(["InjuryStep 0", "IncapacitationStep 0", "IncapacitationStep 1", "TieStep 0"])
	assert_array(entered).contains(["BreathDiceStep 0", "BreathDiceStep 1", "InjuryStep 1"])
	assert_str(_fight.end_exchange()).is_empty()
	assert_int(_fight.outcome).is_equal(Fight.Outcome.ONGOING)

func test_a_tie_is_told() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d6], [5]), FightTestDice.scores(7))
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [5]), FightTestDice.scores(7))
	_fight.apply_exchange(FightExchange.new(player, opponent), player.lost_breath_dice)
	assert_str(_fight.get_exchange_summary()).contains("Neither of you gives way at 5")

func test_no_tie_line_when_the_threats_differ() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d6], [5]), FightTestDice.scores(7))
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [4]), FightTestDice.scores(7))
	_fight.apply_exchange(FightExchange.new(player, opponent), player.lost_breath_dice)
	assert_str(_fight.get_exchange_summary()).not_contains("gives way")
