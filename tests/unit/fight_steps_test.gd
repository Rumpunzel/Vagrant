extends GdUnitTestSuite

## Exchange steps: each applies its part when entered, whatever order exchange_steps.tres gives them within their phase
## (only the resolution is authored; the other phases are fixed in code).

const GUTS: CharacterAttribute = Rules.STRENGTH
var _side_steps: Array[Script] = [DiceStep, UnnervingStep, WeaponCheckStep, BreathDiceStep, VantageStep, ShieldStep, ArmorStep, InjuryStep, IncapacitationStep]

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
	_fight = Fight.new(AdventureFightDecision.new(), _character, _monster, _character)

func test_authored_order_has_every_step_once_per_side() -> void:
	var steps: Array[ExchangeStep] = _fight.exchange_steps.get_steps()
	for step_class: Script in _side_steps:
		for side: ExchangeStep.ExchangeSide in [ExchangeStep.ExchangeSide.FIRST, ExchangeStep.ExchangeSide.SECOND]:
			var matching: Array = steps.filter(func(step: ExchangeStep) -> bool: return is_instance_of(step, step_class) and step.side == side)
			assert_int(matching.size()).override_failure_message("%s for side %d" % [step_class.get_global_name(), side]).is_equal(1)
	assert_int(steps.filter(func(step: ExchangeStep) -> bool: return step is TieStep).size()).is_equal(1)

func test_steps_apply_their_part_only_when_entered() -> void:
	# 9 vs 8: the player's 9 is lost (Guts 7), the monster's 8 and 7 too (Guts 5); unarmed, only the winner's vantage of 1 hurts
	var player: FightSide = FightSide.new(GUTS, FightTestDice.player_dice([1, 1, 2, 2, 9]), FightTestDice.scores(7))
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.lurker_dice([8, 7, 1]), FightTestDice.scores(5))
	_fight.start_exchange(FightExchange.new(player, opponent))
	var entered: Array[String] = []
	while _fight.is_exchange_pending():
		var step: ExchangeStep = _fight.get_current_step()
		var player_dice: int = _character.get_breath_dice_count_for(Rules.d12)
		var monster_dice: int = _monster.breath_dice[Rules.d8]
		var monster_injury: int = _monster.get_injury_total()
		var told: String = _fight.advance()
		var player_breath_step: bool = step is BreathDiceStep and step.is_first()
		var monster_breath_step: bool = step is BreathDiceStep and not step.is_first()
		assert_int(_character.get_breath_dice_count_for(Rules.d12)).is_equal(player_dice - 1 if player_breath_step else player_dice)
		assert_int(_monster.breath_dice[Rules.d8]).is_equal(monster_dice - 2 if monster_breath_step else monster_dice)
		assert_int(_monster.get_injury_total()).is_equal(monster_injury + 1 if step is InjuryStep and not step.is_first() else monster_injury)
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
	_fight.apply_exchange(FightExchange.new(player, opponent))
	assert_str(_fight.get_exchange_summary()).contains("Neither of you gives way at 5")

func test_no_tie_line_when_the_threats_differ() -> void:
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d6], [5]), FightTestDice.scores(7))
	var opponent: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [4]), FightTestDice.scores(7))
	_fight.apply_exchange(FightExchange.new(player, opponent))
	assert_str(_fight.get_exchange_summary()).not_contains("gives way")

func test_guts_and_blood_vantage_are_told() -> void:
	# 4 vs 2: the player's Guts add 2 to the Sword's 1 (the Cutthroat keeps Guts 2); then 8 vs 5 (the Cutthroat's 5 threatens too) with Blood: 3 off its 5
	var guts: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d6], [4]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 1))
	_fight.apply_exchange(FightExchange.new(guts, FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [2]), FightTestDice.scores(7))))
	assert_str(_fight.get_exchange_summary()).contains("You press your advantage: +2 to your blow.")
	var blood: FightSide = FightSide.new(Rules.AGILITY, FightTestDice.dice([Rules.d8], [8]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 1))
	var armed: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [2]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d8, 5))
	_fight.apply_exchange(FightExchange.new(blood, armed))
	assert_str(_fight.get_exchange_summary()).contains("You dodge 3 of the Cutthroat's blow.")

func test_peasant_tells_the_breath_dice_it_spared() -> void:
	_grant("Peasant", HighestBreathDieLossAbility.new())
	# All three of the player's dice are above Guts 1, the Peasant only loses the highest
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4, Rules.d6, Rules.d8], [2, 3, 4]), FightTestDice.scores(1))
	_fight.apply_exchange(FightExchange.new(player, FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [1]), FightTestDice.scores(7))))
	assert_str(_fight.get_exchange_summary()).contains("You lose 1 breath die. Peasant spares you 2 of 3 breath dice.")

func test_no_peasant_note_when_nothing_was_spared() -> void:
	_grant("Peasant", HighestBreathDieLossAbility.new())
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [4]), FightTestDice.scores(1))
	_fight.apply_exchange(FightExchange.new(player, FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [1]), FightTestDice.scores(7))))
	assert_str(_fight.get_exchange_summary()).contains("You lose 1 breath die.")
	assert_str(_fight.get_exchange_summary()).not_contains("spares")

func test_veteran_tells_the_vantage_it_doubled() -> void:
	var veteran: VantageMultiplierAbility = VantageMultiplierAbility.new()
	_grant("Veteran", veteran)
	# 4 vs 2 with Guts: a vantage of 2, doubled
	var player: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d6], [4]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d10, 1))
	player.abilities = [veteran] as Array[Ability]
	_fight.apply_exchange(FightExchange.new(player, FightSide.new(GUTS, FightTestDice.dice([Rules.d8], [2]), FightTestDice.scores(7))))
	assert_str(_fight.get_exchange_summary()).contains("You press your advantage: +4 to your blow. Veteran turns your vantage of 2 into 4.")

func test_forcing_tells_what_it_does_to_the_weapon() -> void:
	var sword: Weapon = Weapon.create(WeaponProfile.create("Sword", Rules.d10), [10] as Array[int])
	var side: FightSide = FightSide.new(GUTS, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(7), FightTestDice.dice([Rules.d10, Rules.d10], [8, 9]))
	side.weapon = sword
	side.marked_faces = sword.marked_faces.duplicate()
	assert_str(CommitStep.describe_weapon_die(side, side.weapon_dice[0])).is_equal("Force the 8: −1 threat, marks the 8 (8 of 10 faces left).")
	assert_str(CommitStep.describe_weapon_die(side, side.weapon_dice[1])).is_equal("Force the 9: −2 threat, marks the 9, then it is ruined.")
	assert_array(sword.marked_faces).is_equal([10])

## The player's first origin gets [param ability] and is called [param origin_name]
func _grant(origin_name: String, ability: Ability) -> void:
	var origin: Origin = _character.character_profile.origins[0]
	origin.name = origin_name
	origin.abilities = [ability] as Array[Ability]
