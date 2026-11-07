extends GdUnitTestSuite

## The Fight Lab's own headless process: a scenario saved in no file goes inside the settings, and the result comes back.

const SETTINGS: String = "user://fight_lab/test/settings.tres"
const OUT: String = "user://fight_lab/test/result.json"

func test_a_run_in_its_own_process_comes_back() -> void:
	var scenario: FightLabScenario = FightLabScenario.new()
	scenario.side_a = [TestCharacters.adventurer()] as Array[ActorProfile]
	scenario.side_b = [TestMonsters.cutthroat()] as Array[ActorProfile]
	var settings: FightLabRunSettings = FightLabRunSettings.new()
	settings.scenario = scenario
	settings.fights = 3
	var process: FightLabProcess = auto_free(FightLabProcess.new())
	add_child(process)
	var results: Array[Dictionary] = []
	process.finished.connect(func(result: Dictionary) -> void: results.append(result))
	assert_bool(process.start(settings, SETTINGS, OUT)).is_true()
	assert_bool(process.is_running()).is_true()
	for _wait: int in 600:
		if not process.is_running(): break
		await await_millis(100)
	assert_bool(process.is_running()).is_false()
	assert_array(results[0]["side_a"]).is_equal(["Tester"])
	assert_int(int(results[0]["cells"][0]["stats"]["runs"])).is_equal(3)

func test_a_failed_run_tells_why() -> void:
	# No scenario: the runner refuses
	var process: FightLabProcess = auto_free(FightLabProcess.new())
	add_child(process)
	var results: Array[Dictionary] = []
	process.finished.connect(func(result: Dictionary) -> void: results.append(result))
	assert_bool(process.start(FightLabRunSettings.new(), SETTINGS, OUT)).is_true()
	for _wait: int in 600:
		if not process.is_running(): break
		await await_millis(100)
	assert_dict(results[0]).is_empty()
	assert_str(process.get_errors()).contains("Fight Lab: needs")
