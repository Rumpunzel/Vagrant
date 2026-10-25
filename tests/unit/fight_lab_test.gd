extends GdUnitTestSuite

## Fight Lab: scenarios, sweeps, simulated fights and their summary.

var _strategy: FightLabStrategy

func before_test() -> void:
	_strategy = FightLabStrategy.new()

func test_a_simulated_fight_ends_and_is_recorded() -> void:
	var record: Dictionary[String, Variant] = FightLabSimulator.new(self).simulate(_matchup(TestCharacters.adventurer(), TestMonsters.cutthroat()), 50)
	assert_array(FightLabSimulator.OUTCOMES.values()).contains([record["outcome"]])
	assert_int(record["exchanges"]).is_between(1, 50)
	assert_int(record["breath_left"]).is_greater_equal(0)
	for key: String in FightLabStats.NUMBERS + FightLabStats.RATES: assert_bool(record.has(key)).override_failure_message(key).is_true()

func test_simulated_fights_leave_no_nodes_behind() -> void:
	var simulator: FightLabSimulator = FightLabSimulator.new(self)
	var children: int = get_child_count()
	for _run: int in 5: simulator.simulate(_matchup(TestCharacters.adventurer(), TestMonsters.cutthroat()), 50)
	assert_int(get_child_count()).is_equal(children)

func test_a_fight_stops_after_max_exchanges() -> void:
	var record: Dictionary[String, Variant] = FightLabSimulator.new(self).simulate(_matchup(TestCharacters.adventurer(), TestMonsters.cutthroat()), 1)
	assert_int(record["exchanges"]).is_equal(1)

func test_fleeing_at_full_breath_flees_at_once() -> void:
	_strategy.flee_at_breath_dice = 15
	var record: Dictionary[String, Variant] = FightLabSimulator.new(self).simulate(_matchup(TestCharacters.adventurer(), TestMonsters.cutthroat()), 50)
	assert_array(["fled", "lost"]).contains([record["outcome"]])
	assert_int(record["exchanges"]).is_equal(1)

func test_summary_shares_means_and_histograms() -> void:
	var records: Array[Dictionary] = [_record("won", 2, 6), _record("won", 4, 2), _record("lost", 6, 0)]
	var stats: Dictionary[String, Variant] = FightLabStats.summarize(records)
	assert_int(stats["runs"]).is_equal(3)
	assert_float(stats["outcomes"]["won"]).is_equal_approx(2.0 / 3.0, 0.001)
	assert_float(stats["outcomes"]["lost"]).is_equal_approx(1.0 / 3.0, 0.001)
	assert_float(stats["means"]["exchanges"]).is_equal(4.0)
	assert_float(stats["rates"]["weapon_ruined"]).is_equal_approx(1.0 / 3.0, 0.001)
	assert_dict(stats["histograms"]["exchanges"]).is_equal({"2": 1, "4": 1, "6": 1})

func test_summary_tells_what_winning_cost() -> void:
	var records: Array[Dictionary] = [_record("won", 2, 6), _record("won", 4, 2), _record("lost", 6, 0)]
	records[0]["taken"] = 3
	records[1]["taken"] = 5
	records[2]["taken"] = 20
	var won: Dictionary = FightLabStats.summarize(records)["won"]
	assert_int(won["runs"]).is_equal(2)
	assert_float(won["means"]["taken"]).is_equal(4.0)
	assert_dict(won["histograms"]["taken"]).is_equal({"3": 1, "5": 1})

func test_summary_counts_values_per_outcome() -> void:
	var records: Array[Dictionary] = [_record("won", 2, 6), _record("won", 2, 2), _record("lost", 6, 0)]
	var by_outcome: Dictionary = FightLabStats.summarize(records)["by_outcome"]
	assert_dict(by_outcome["exchanges"]["won"]).is_equal({"2": 2})
	assert_dict(by_outcome["exchanges"]["lost"]).is_equal({"6": 1})
	assert_dict(by_outcome["exchanges"]["draw"]).is_empty()

func test_percentiles_of_a_histogram() -> void:
	var results: GDScript = load("uid://cuh3q2c6v1lmb")  # fight_lab_results.gd
	# Ten fights: 1 ×1, 2 ×4, 3 ×4, 9 ×1
	assert_array(results._percentiles({"1": 1, "2": 4, "3": 4, "9": 1})).is_equal([1.0, 2.0, 2.0, 3.0, 3.0])
	assert_array(results._percentiles({})).is_empty()

func test_scenario_has_a_matchup_per_pairing_and_sweep_value() -> void:
	var scenario: FightLabScenario = FightLabScenario.new()
	scenario.side_a = [TestCharacters.adventurer(), TestCharacters.adventurer()] as Array[ActorProfile]
	scenario.side_b = [TestMonsters.cutthroat()] as Array[ActorProfile]
	assert_int(scenario.get_matchups().size()).is_equal(2)
	var sweep: FightLabForcingSweep = FightLabForcingSweep.new()
	sweep.from = 0
	sweep.to = 3
	var matchups: Array[FightLabMatchup] = scenario.get_matchups(sweep)
	assert_int(matchups.size()).is_equal(8)
	assert_array(matchups.map(func(matchup: FightLabMatchup) -> int: return matchup.sweep_value)).is_equal([0, 1, 2, 3, 0, 1, 2, 3])
	assert_array(matchups.map(func(matchup: FightLabMatchup) -> int: return matchup.a_index)).is_equal([0, 0, 0, 0, 1, 1, 1, 1])

func test_characters_without_rolled_attributes_are_skipped() -> void:
	var unrolled: CharacterProfile = TestCharacters.adventurer()
	unrolled.attribute_scores = {}
	var scenario: FightLabScenario = FightLabScenario.new()
	scenario.side_a = [unrolled, TestCharacters.adventurer()] as Array[ActorProfile]
	scenario.side_b = [TestMonsters.cutthroat()] as Array[ActorProfile]
	assert_array(scenario.get_skipped()).contains_exactly([unrolled])
	assert_int(scenario.get_matchups().size()).is_equal(1)

func test_attribute_sweep_changes_copies_only() -> void:
	var character_profile: CharacterProfile = TestCharacters.adventurer()
	var monster_profile: MonsterProfile = TestMonsters.cutthroat()
	var matchup: FightLabMatchup = _matchup(character_profile, monster_profile)
	var sweep: FightLabAttributeSweep = FightLabAttributeSweep.new()
	sweep.attribute = Rules.STRENGTH
	sweep.apply(11, matchup)
	assert_int(matchup.profile_a.get_attribute_score(Rules.STRENGTH)).is_equal(11)
	assert_int(character_profile.attribute_scores[Rules.STRENGTH].get_score()).is_equal(7)
	sweep.side = FightLabAttributeSweep.Team.B
	sweep.apply(2, matchup)
	assert_int(matchup.profile_b.get_attribute_score(Rules.STRENGTH)).is_equal(2)
	assert_int(monster_profile.attribute_scores[Rules.STRENGTH]).is_not_equal(2)

func test_forcing_sweep_sets_the_strategy_copy() -> void:
	var matchup: FightLabMatchup = _matchup(TestCharacters.adventurer(), TestMonsters.cutthroat())
	var sweep: FightLabForcingSweep = FightLabForcingSweep.new()
	sweep.apply(2, matchup)
	assert_int((matchup.strategy_a.weapon_tactic as ForcingWeaponTactic).max_overshoot).is_equal(2)
	assert_object(_strategy.weapon_tactic).is_null()

func test_run_summarizes_every_cell() -> void:
	var settings: FightLabRunSettings = _settings()
	settings.fights = 10
	var result: Dictionary[String, Variant] = FightLabRun.new(settings).execute(self)
	assert_str(result["sweep"]).is_empty()
	assert_array(result["side_a"]).is_equal(["Tester"])
	assert_int(result["cells"].size()).is_equal(1)
	assert_int(result["cells"][0]["stats"]["runs"]).is_equal(10)
	assert_str(JSON.stringify(result)).is_not_empty()

func test_one_fight_is_logged_exchange_by_exchange() -> void:
	var settings: FightLabRunSettings = _settings()
	settings.mode = FightLabRunSettings.Mode.ONE_FIGHT
	var result: Dictionary[String, Variant] = FightLabRun.new(settings).execute(self)
	assert_bool(result.has("cells")).is_false()
	var record: Dictionary = result["fight"]["record"]
	var exchange_log: Array = record["log"]
	assert_int(exchange_log.size()).is_equal(record["exchanges"])
	assert_str(exchange_log[0]["text"]).contains("threaten")
	assert_int(exchange_log[-1]["breath"]).is_equal(record["breath_left"])

func test_two_monsters_can_fight() -> void:
	var record: Dictionary[String, Variant] = FightLabSimulator.new(self).simulate(_matchup(TestMonsters.cutthroat(), TestMonsters.cutthroat()), 50)
	assert_array(FightLabSimulator.OUTCOMES.values()).contains([record["outcome"]])
	assert_int(record["exchanges"]).is_between(1, 50)

func test_two_characters_are_told_in_the_third_person() -> void:
	var settings: FightLabRunSettings = _settings()
	settings.scenario.side_b = [TestCharacters.adventurer()] as Array[ActorProfile]
	settings.mode = FightLabRunSettings.Mode.ONE_FIGHT
	var text: String = FightLabRun.new(settings).execute(self)["fight"]["record"]["log"][0]["text"]
	assert_str(text).contains("Tester threatens")
	assert_str(text).not_contains("You ")

func _matchup(profile_a: ActorProfile, profile_b: ActorProfile) -> FightLabMatchup:
	var matchup: FightLabMatchup = FightLabMatchup.new(profile_a, profile_b)
	matchup.strategy_a = _strategy
	matchup.strategy_b = _strategy
	return matchup

func _settings() -> FightLabRunSettings:
	var scenario: FightLabScenario = FightLabScenario.new()
	scenario.side_a = [TestCharacters.adventurer()] as Array[ActorProfile]
	scenario.side_b = [TestMonsters.cutthroat()] as Array[ActorProfile]
	var settings: FightLabRunSettings = FightLabRunSettings.new()
	settings.scenario = scenario
	return settings

func _record(outcome: String, exchanges: int, dealt: int) -> Dictionary:
	var record: Dictionary = {"outcome": outcome, "exchanges": exchanges, "dealt": dealt, "taken": 1, "breath_left": 2, "breath_spent": 3, "foe_breath_left": 0, "weapon_dropped": false, "shield_dropped": false}
	for key: String in ["weapon_marks", "shield_marks", "armor_marks", "shield_ruined", "armor_ruined"]: record[key] = 0
	record["weapon_ruined"] = int(outcome == "lost")
	return record
