class_name FightLabRun
extends RefCounted

## Simulates as [FightLabRunSettings] say and returns what the Fight Lab dock draws, ready for JSON

signal progressed(done: int, total: int)

var settings: FightLabRunSettings

func _init(with_settings: FightLabRunSettings) -> void:
	assert(with_settings and with_settings.scenario)
	settings = with_settings

## Many fights: { characters, monsters, skipped, sweep: label or "", sweep_values, cells: [{character, monster, value, stats}] },
## character and monster being indices into the name lists; see [method FightLabStats.summarize].
## One fight: { characters, monsters, fight: {character, monster, record} } with the record's exchange log.
func execute(parent: Node) -> Dictionary[String, Variant]:
	if settings.random_seed != 0: seed(settings.random_seed)
	var scenario: FightLabScenario = settings.scenario
	var simulator: FightLabSimulator = FightLabSimulator.new(parent)
	var result: Dictionary[String, Variant] = {"characters": _names(scenario.characters), "monsters": _names(scenario.monsters)}
	if settings.mode == FightLabRunSettings.Mode.ONE_FIGHT:
		var matchup: FightLabMatchup = scenario.get_matchup(settings.character, settings.monster)
		result["fight"] = {"character": settings.character, "monster": settings.monster, "record": simulator.simulate(matchup, settings.max_exchanges, true)}
		progressed.emit(1, 1)
		return result
	var matchups: Array[FightLabMatchup] = scenario.get_matchups(settings.sweep)
	var cells: Array[Dictionary] = []
	for index: int in matchups.size():
		var matchup: FightLabMatchup = matchups[index]
		var records: Array[Dictionary] = []
		for _fight: int in settings.fights: records.append(simulator.simulate(matchup, settings.max_exchanges))
		cells.append({"character": matchup.character_index, "monster": matchup.monster_index, "value": matchup.sweep_value, "stats": FightLabStats.summarize(records)})
		progressed.emit(index + 1, matchups.size())
	result["skipped"] = _names(scenario.get_skipped_characters())
	result["sweep"] = settings.sweep.get_label() if settings.sweep else ""
	result["sweep_values"] = settings.sweep.get_values() if settings.sweep else []
	result["cells"] = cells
	return result

static func _names(profiles: Array) -> Array[String]:
	var names: Array[String] = []
	for profile: Resource in profiles: names.append(profile.get("name") if profile else "(empty)")
	return names
