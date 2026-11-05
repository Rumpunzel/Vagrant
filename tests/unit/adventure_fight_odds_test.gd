extends GdUnitTestSuite

## The adventure editor's fight odds: which monster each fight fights, the reference fighters' scenario, odds read back and when they are out of date.

const ADVENTURE_PATH: String = "res://tests/fight_odds_adventure.tres"

var _shore: AdventureLocation
var _lurker: AdventureEncounter
var _ambush: AdventureFightDecision
var _odds: AdventureFightOdds

func before_test() -> void:
	_shore = AdventureLocation.new()
	_shore.title = "Shore"
	_shore.area = AdventureArea.new()
	_lurker = AdventureEncounter.new()
	_lurker.title = "Lurker"
	_lurker.profile = TestMonsters.cutthroat()
	var event: AdventureEvent = AdventureEvent.new()
	event.title = "Ambush"
	_ambush = AdventureFightDecision.new()
	event.decisions = [_ambush] as Array[AdventureDecision]
	_lurker.events = [event] as Array[AdventureEvent]
	_odds = auto_free(AdventureFightOdds.new())

func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(AdventureFightOdds.DIRECTORY + str(ADVENTURE_PATH.hash()) + ".json"))

func test_each_fight_fights_the_monster_the_story_picks() -> void:
	var brute: MonsterProfile = TestMonsters.brute()
	var one_off: AdventureFightDecision = AdventureFightDecision.new()
	one_off.enemies = [brute, TestMonsters.cutthroat()] as Array[MonsterProfile]
	_shore.decisions = [one_off] as Array[AdventureDecision]
	var found: Dictionary[AdventureFightDecision, MonsterProfile] = AdventureFightOdds.find_monsters(AdventureGraph.new(_adventure()))
	assert_object(found[_ambush]).is_same(_lurker.profile)
	assert_object(found[one_off]).is_same(brute)
	# The encounter's monster comes before enemies, as in the story
	_ambush.enemies = [brute] as Array[MonsterProfile]
	assert_object(_ambush.get_monster_profile(_lurker)).is_same(_lurker.profile)
	assert_object(AdventureFightDecision.new().get_monster_profile(null)).is_null()

func test_the_reference_fighters_fight_the_monsters_in_a_scenario_of_their_own() -> void:
	var scenario: FightLabScenario = AdventureFightOdds.make_scenario([TestMonsters.cutthroat()] as Array[MonsterProfile])
	assert_array(scenario.side_a.map(func(profile: ActorProfile) -> String: return profile.name)).is_equal(["Weak", "Average", "Strong"])
	assert_int(scenario.side_b.size()).is_equal(1)
	assert_str(scenario.resource_path).is_empty()
	assert_array((load(AdventureFightOdds.REFERENCE) as FightLabScenario).side_b).is_empty()

func test_reference_fighters_can_fight_and_get_stronger() -> void:
	var totals: Array[int] = []
	for profile: ActorProfile in (load(AdventureFightOdds.REFERENCE) as FightLabScenario).side_a:
		assert_bool(profile.can_fight()).is_true()
		var total: int = 0
		for attribute: CharacterAttribute in Rules.ATTRIBUTES: total += profile.get_attribute_score(attribute)
		totals.append(total)
	assert_bool(totals[0] < totals[1] and totals[1] < totals[2]).is_true()

func test_odds_are_read_back_per_fight() -> void:
	_save_result({})
	var adventure: Adventure = _adventure()
	_odds.index(adventure, AdventureGraph.new(adventure))
	var odds: Array[Dictionary] = _odds.get_odds(_ambush)
	assert_array(odds.map(func(entry: Dictionary) -> String: return entry["name"])).is_equal(["Weak", "Strong"])
	assert_float(odds[1]["stats"]["outcomes"]["won"]).is_equal(0.9)
	assert_bool(_odds.is_out_of_date(_ambush)).is_false()
	var unknown: AdventureFightDecision = AdventureFightDecision.new()
	unknown.enemies = [TestMonsters.brute()] as Array[MonsterProfile]
	assert_array(_odds.get_odds(unknown)).is_empty()

func test_the_fight_tooltip_names_the_monster_and_tabulates_the_odds() -> void:
	_save_result({})
	var adventure: Adventure = _adventure()
	var graph: AdventureGraph = AdventureGraph.new(adventure)
	_odds.index(adventure, graph)
	var tooltips: AdventureTooltips = AdventureTooltips.new(graph)
	tooltips.fight_odds = _odds
	var text: String = tooltips.describe(_ambush)
	assert_str(text).contains("Fight against %s" % _lurker.profile.name)
	# Won and lost happened, so they are columns; the rest isn't
	assert_str(text).contains("[table=4]").contains("Won").contains("Lost").not_contains("]Fled[/color]")
	assert_str(text).contains("[b]Strong[/b]").contains("90%")
	tooltips.fight_odds = null
	assert_str(tooltips.describe(_ambush)).not_contains("Fight Lab")

func test_changed_reference_fighters_make_odds_out_of_date() -> void:
	_save_result({"reference:res://addons/fight_lab/fighters/weak.tres": 1})
	var adventure: Adventure = _adventure()
	_odds.index(adventure, AdventureGraph.new(adventure))
	assert_bool(_odds.is_out_of_date(_ambush)).is_true()

func _adventure() -> Adventure:
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = _shore
	adventure.encounters = [_lurker] as Array[AdventureEncounter]
	adventure.resource_path = ADVENTURE_PATH
	return adventure

## As a run of the reference fighters (two of them here) against the Lurker's monster would leave it; the monster is in no file (stamp 0)
func _save_result(stamps: Dictionary) -> void:
	var cells: Array[Dictionary] = []
	for a: int in 2:
		var won: float = 0.2 if a == 0 else 0.9
		var outcomes: Dictionary = {"won": won, "lost": 1.0 - won, "draw": 0.0, "fled": 0.0, "unfinished": 0.0}
		cells.append({"a": a, "b": 0, "value": 0, "stats": {"outcomes": outcomes, "won": {"runs": 0}}})
	var all_stamps: Dictionary = {"": 0}
	all_stamps.merge(stamps)
	var result: Dictionary = {"side_a": ["Weak", "Strong"], "side_b": [_lurker.profile.name], "cells": cells, "monsters": [_lurker.profile.name], "stamps": all_stamps}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AdventureFightOdds.DIRECTORY))
	var file: FileAccess = FileAccess.open(AdventureFightOdds.DIRECTORY + str(ADVENTURE_PATH.hash()) + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
