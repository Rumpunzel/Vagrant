class_name FightLabRun
extends RefCounted

## Simulates a whole [FightLabScenario] and returns what the Fight Lab dock draws, ready for JSON

signal progressed(done: int, total: int)

var scenario: FightLabScenario

func _init(for_scenario: FightLabScenario) -> void:
	assert(for_scenario)
	scenario = for_scenario

## { sweep: label or "", skipped: [character names], cells: [{character, monster, value, stats}] }; see [method FightLabStats.summarize]
func execute(parent: Node) -> Dictionary[String, Variant]:
	if scenario.random_seed != 0: seed(scenario.random_seed)
	var simulator: FightLabSimulator = FightLabSimulator.new(parent)
	var matchups: Array[FightLabMatchup] = scenario.get_matchups()
	var cells: Array[Dictionary] = []
	for index: int in matchups.size():
		var matchup: FightLabMatchup = matchups[index]
		var records: Array[Dictionary] = []
		for _run: int in scenario.runs: records.append(simulator.simulate(matchup, scenario.max_exchanges))
		cells.append({
			"character": matchup.character_profile.name,
			"monster": matchup.monster_profile.name,
			"value": matchup.sweep_value,
			"stats": FightLabStats.summarize(records),
		})
		progressed.emit(index + 1, matchups.size())
	var skipped: Array[String] = []
	for character_profile: CharacterProfile in scenario.get_skipped_characters(): skipped.append(character_profile.name if character_profile else "(empty)")
	return {"sweep": scenario.sweep.get_label() if scenario.sweep else "", "skipped": skipped, "cells": cells}
