extends GdUnitTestSuite

## What the Fight Lab's tooltips say: pairing summaries, fighter cards (linked), exchanges of a single fight.

var _tooltips: FightLabTooltips

func before_test() -> void:
	var sword: WeaponProfile = WeaponProfile.new()
	sword.name = "Sword"
	sword.die = Rules.d10
	var character: CharacterProfile = TestCharacters.adventurer()
	character.weapons = [sword] as Array[WeaponProfile]
	var scenario: FightLabScenario = FightLabScenario.new()
	scenario.side_a = [character] as Array[ActorProfile]
	scenario.side_b = [TestMonsters.cutthroat()] as Array[ActorProfile]
	_tooltips = FightLabTooltips.new()
	_tooltips.scenario = scenario
	_tooltips.result = {"side_a": ["Tester"], "side_b": [TestMonsters.cutthroat().name]}

func test_a_cell_summary_links_both_fighters_and_tells_the_outcomes() -> void:
	var records: Array[Dictionary] = []
	for outcome: String in ["won", "won", "lost", "won"]:
		records.append({"outcome": outcome, "exchanges": 2, "dealt": 3, "taken": 1, "breath_left": 2, "breath_spent": 3, "foe_breath_left": 0,
			"weapon_marks": 0, "shield_marks": 0, "armor_marks": 0, "weapon_ruined": 0, "weapon_dropped": false, "shield_ruined": 0,
			"shield_dropped": false, "armor_ruined": 0})
	var text: String = _tooltips.describe_cell(0, 0, [{"a": 0, "b": 0, "value": 0, "stats": FightLabStats.summarize(records)}] as Array[Dictionary])
	assert_str(text).contains("[url=a:0]").contains("[url=b:0]")
	assert_str(text).contains("won 75%, lost 25% (4 fights)")
	assert_str(text).contains("median 2 exchanges")
	assert_str(text).contains("1 injury, 3 breath dice")

func test_a_fighter_card_tells_scores_gear_and_how_to_open_it() -> void:
	var text: String = _tooltips.describe_fighter("a", 0)
	assert_str(text).contains("[b]Tester[/b]").contains("character")
	assert_str(text).contains("Sword (d10")
	assert_str(text).contains("Click: open it in the Inspector")
	var monster: String = _tooltips.describe_fighter("b", 0)
	assert_str(monster).contains("monster").contains("Attack:").contains("Tactics:")

func test_links_lead_to_fighters_and_exchanges() -> void:
	assert_str(_tooltips.describe_link("a:0")).contains("[b]Tester[/b]")
	assert_str(_tooltips.describe_link("nonsense")).is_empty()
	_tooltips.result["fight"] = {"a": 0, "b": 0}
	_tooltips.exchange_log = [{"threat": 5, "foe_threat": 3, "breath": 4, "foe_breath": 2, "injuries": 0, "foe_injuries": 2}]
	assert_str(_tooltips.describe_link("exchange:1")).contains("Threat: Tester 5")
	assert_str(_tooltips.describe_link("exchange:2")).is_empty()

func test_a_character_row_tells_its_strategy() -> void:
	var risky: FightLabStrategy = FightLabStrategy.new()
	risky.breath_dice = FightLabStrategy.BreathDiceChoice.SAFE_PLUS_RISKY
	_tooltips.scenario.strategies_a = [FightLabStrategy.new(), risky] as Array[FightLabStrategy]
	_tooltips.result = {"side_a": ["Tester · Safe", "Tester · Safe + 1 risky"], "side_b": []}
	assert_str(_tooltips.describe_fighter("a", 1)).contains("[b]Strategy Safe + 1 risky[/b]").contains("the 1 smallest that can be lost")
	assert_str(_tooltips.describe_fighter("a", 0)).contains("only those that can't be lost")

func test_a_fighter_no_longer_in_the_scenario_says_so() -> void:
	_tooltips.result = {"side_a": ["Someone else"], "side_b": []}
	assert_str(_tooltips.describe_fighter("a", 0)).contains("Not in the scenario any more")
