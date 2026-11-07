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
	# Each fights with Guts, Blood and Nerves
	assert_int(scenario.get_row_count()).is_equal(9)
	assert_str(scenario.get_row_name(1)).is_equal("Weak · Blood")
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
	assert_array(odds.map(func(entry: Dictionary) -> String: return "%s · %s" % [entry["name"], entry["approach"]])).is_equal(["Weak · Guts", "Weak · Blood", "Strong · Guts", "Strong · Blood"])
	# Each fighter's best approach, in their order
	assert_array(AdventureFightOdds.get_best(odds).map(func(entry: Dictionary) -> String: return "%s · %s" % [entry["name"], entry["approach"]])).is_equal(["Weak · Blood", "Strong · Guts"])
	assert_float(AdventureFightOdds.get_won(odds[2])).is_equal(0.9)
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
	# A heading row per fighter, a row per approach in its attribute's colour; won and lost happened, the medians follow; each fighter's best in bold
	assert_str(text).contains("[table=6]").contains("[b]3[/b] / 1").contains("[b]Strong[/b]").contains("color=#%s]%s[/img]" % [Rules.AGILITY.color.to_html(), Rules.AGILITY.icon.resource_path])
	assert_str(text).contains("[b]90%[/b]").contains("[b]40%[/b]").contains("30%").not_contains("]Fled[/color]")
	tooltips.fight_odds = null
	assert_str(tooltips.describe(_ambush)).not_contains("Fight Lab")

func test_changed_reference_fighters_make_odds_out_of_date() -> void:
	_save_result({"reference:res://addons/fight_lab/fighters/weak.tres": "an older weak.tres"})
	var adventure: Adventure = _adventure()
	_odds.index(adventure, AdventureGraph.new(adventure))
	assert_bool(_odds.is_out_of_date(_ambush)).is_true()

func _adventure() -> Adventure:
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = _shore
	adventure.encounters = [_lurker] as Array[AdventureEncounter]
	adventure.resource_path = ADVENTURE_PATH
	return adventure

## As a run of the reference fighters (two of them here, with two approaches) against the Lurker's monster would leave it; the monster is in no
## file (no stamp)
func _save_result(stamps: Dictionary) -> void:
	var cells: Array[Dictionary] = []
	var shares: Array[float] = [0.2, 0.4, 0.9, 0.3]
	for a: int in shares.size():
		var outcomes: Dictionary = {"won": shares[a], "lost": 1.0 - shares[a], "draw": 0.0, "fled": 0.0, "unfinished": 0.0}
		var histograms: Dictionary = {"dealt": {str(2 + a): 1}, "taken": {"1": 1}, "breath_spent": {"2": 1}, "exchanges": {"3": 1}}
		cells.append({"a": a, "b": 0, "value": 0, "stats": {"outcomes": outcomes, "won": {"runs": 0}, "histograms": histograms}})
	var all_stamps: Dictionary = {"": ""}
	all_stamps.merge(stamps)
	var result: Dictionary = {
		"side_a": ["Weak · Guts", "Weak · Blood", "Strong · Guts", "Strong · Blood"], "side_b": [_lurker.profile.name], "cells": cells,
		"monsters": [_lurker.profile.name], "stamps": all_stamps, "fighters": ["Weak", "Weak", "Strong", "Strong"], "approaches": ["Guts", "Blood", "Guts", "Blood"],
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(AdventureFightOdds.DIRECTORY))
	var file: FileAccess = FileAccess.open(AdventureFightOdds.DIRECTORY + str(ADVENTURE_PATH.hash()) + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(result))
	file.close()
