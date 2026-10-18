extends GdUnitTestSuite

## Fight state across exchanges, with fixed dice fed straight into [method Fight.apply_exchange].

const GUTS: CharacterAttribute = Rules.STRENGTH
const BLOOD: CharacterAttribute = Rules.AGILITY

var _character: Character
var _monster: Monster
var _decision: AdventureFightDecision
var _won: AdventurePage
var _lost: AdventurePage
var _draw: AdventurePage
var _fled: AdventurePage

func before_test() -> void:
	_character = auto_free(load("res://characters/character.tscn").instantiate())
	add_child(_character)
	_character.character_profile = (load("res://characters/dorian.tres") as CharacterProfile).duplicate(true)
	_monster = auto_free(load("res://characters/monsters/monster.tscn").instantiate())
	add_child(_monster)
	_monster.monster_profile = load("res://characters/monsters/lurker.tres")
	_won = AdventurePage.new()
	_lost = AdventurePage.new()
	_draw = AdventurePage.new()
	_fled = AdventurePage.new()
	_decision = AdventureFightDecision.new()
	_decision.transition = _won
	_decision.failure_transition = _lost
	_decision.draw_transition = _draw
	_decision.flee_transition = _fled

func test_start_recovers_monster_breath_but_keeps_injuries() -> void:
	_monster.suffer_injury(Injury.new(2))
	_monster.lose_breath_dice(_monster.get_breath_dice_pool())
	assert_bool(_monster.is_out_of_breath()).is_true()
	Fight.new(_decision, _character, _monster)
	assert_bool(_monster.is_out_of_breath()).is_false()
	assert_int(_monster.get_score(GUTS)).is_equal(_lurker_guts() - 2)

func test_unarmed_example_until_won() -> void:
	var fight: Fight = Fight.new(_decision, _character, _monster)
	# Exchange 1: 7 vs 5 -> Lurker injury 2
	_apply(fight, [1, 1, 2, 2, 7], 7, [3, 4, 5], 5)
	assert_int(fight.outcome).is_equal(Fight.Outcome.ONGOING)
	assert_int(_monster.get_score(GUTS)).is_equal(_lurker_guts() - 2)
	# Exchange 2: player loses the 9 (d12), Lurker its two 4s and an injury of 5
	_apply(fight, [2, 2, 4, 7, 9], 7, [3, 4, 4], 3)
	assert_int(fight.outcome).is_equal(Fight.Outcome.ONGOING)
	assert_int(_character.get_breath_dice_count(Rules.d12)).is_equal(0)
	assert_int(_monster.breath_dice[Rules.d8]).is_equal(1)
	assert_int(_monster.get_score(GUTS)).is_equal(_lurker_guts() - 7)
	# Exchange 3: Lurker's last die is lost -> won
	_apply(fight, [1, 1, 2, 2], 7, [1], 0, [Rules.d4, Rules.d6, Rules.d8, Rules.d10], [Rules.d8])
	assert_int(fight.outcome).is_equal(Fight.Outcome.WON)
	assert_object(fight.get_transition()).is_same(_won)
	assert_int(fight.get_exchange_count()).is_equal(3)

func test_player_out_of_breath_loses() -> void:
	var fight: Fight = Fight.new(_decision, _character, _monster)
	_apply(fight, [2, 3, 4, 5, 6], 1, [1, 1, 1], 7)
	assert_int(fight.outcome).is_equal(Fight.Outcome.LOST)
	assert_object(fight.get_transition()).is_same(_lost)

func test_both_out_of_breath_is_a_draw() -> void:
	var fight: Fight = Fight.new(_decision, _character, _monster)
	_apply(fight, [2, 3, 4, 5, 6], 1, [2, 2, 2], 1)
	assert_int(fight.outcome).is_equal(Fight.Outcome.DRAW)
	assert_object(fight.get_transition()).is_same(_draw)

func test_fleeing_ends_the_fight() -> void:
	var fight: Fight = Fight.new(_decision, _character, _monster)
	_apply(fight, [1, 1, 2, 2, 7], 7, [3, 4, 5], 5, [Rules.d4, Rules.d6, Rules.d8, Rules.d10, Rules.d12], [Rules.d8, Rules.d8, Rules.d8], true)
	assert_int(fight.outcome).is_equal(Fight.Outcome.FLED)
	assert_object(fight.get_transition()).is_same(_fled)
	assert_array(fight.get_consequences()).is_empty()

func test_fleeing_out_of_breath_still_flees() -> void:
	# Breath lost while fleeing matters for the next challenge, not this fight
	var fight: Fight = Fight.new(_decision, _character, _monster)
	_apply(fight, [2, 3, 4, 5, 6], 1, [1, 1, 1], 7, [Rules.d4, Rules.d6, Rules.d8, Rules.d10, Rules.d12], [Rules.d8, Rules.d8, Rules.d8], true)
	assert_int(_character.get_breath_dice_count(Rules.d12)).is_equal(0)
	assert_int(fight.outcome).is_equal(Fight.Outcome.FLED)

func test_fleeing_from_monster_out_of_breath_still_flees() -> void:
	var fight: Fight = Fight.new(_decision, _character, _monster)
	_apply(fight, [1, 1, 1, 1, 1], 7, [2, 2, 2], 1, [Rules.d4, Rules.d6, Rules.d8, Rules.d10, Rules.d12], [Rules.d8, Rules.d8, Rules.d8], true)
	assert_bool(_monster.is_out_of_breath()).is_true()
	assert_int(fight.outcome).is_equal(Fight.Outcome.FLED)

func test_starting_out_of_breath_loses_immediately() -> void:
	_character.lose_breath_dice(_character.get_breath_dice_pool())
	var fight: Fight = Fight.new(_decision, _character, _monster)
	assert_int(fight.outcome).is_equal(Fight.Outcome.LOST)
	assert_int(fight.get_exchange_count()).is_equal(0)

func test_injuries_and_losses_reach_both_sides() -> void:
	var fight: Fight = Fight.new(_decision, _character, _monster)
	var guts_before: int = _character.get_attribute_score(GUTS).get_score()
	# 2 vs 5 -> player takes 3
	_apply(fight, [1, 1, 1, 1, 2], 7, [3, 4, 5], 7)
	assert_int(_character.get_attribute_score(GUTS).get_score()).is_equal(guts_before - 3)
	assert_int(_monster.get_score(GUTS)).is_equal(_lurker_guts())

func test_texts() -> void:
	var fight: Fight = Fight.new(_decision, _character, _monster)
	assert_str(fight.create_request().get_description()).contains("The Lurker threatens you with")
	assert_str(fight.get_title()).is_equal("Lurker — Exchange 1")
	assert_str(fight.get_exchange_summary()).is_empty()
	_apply(fight, [1, 1, 2, 2, 7], 7, [3, 4, 5], 5)
	var summary: String = fight.get_exchange_summary()
	assert_str(summary).contains("You threaten with")
	# Injuries have their own display, they are not repeated in the text
	assert_str(summary).not_contains("suffer")
	assert_str(fight.get_title()).is_equal("Lurker — Exchange 2")

func test_condition_description() -> void:
	var fight: Fight = Fight.new(_decision, _character, _monster)
	assert_str(fight.get_condition_description()).is_equal("The Lurker is unhurt and breathes steadily.")
	# Lurker loses both 4s (Guts 3 after the first injury) and takes 5 more
	_apply(fight, [1, 1, 2, 2, 7], 7, [3, 4, 5], 5)
	assert_str(fight.get_condition_description()).is_equal("The Lurker is bleeding and breathes steadily.")
	_apply(fight, [2, 2, 4, 7, 9], 7, [3, 4, 4], 3)
	assert_str(fight.get_condition_description()).is_equal("The Lurker is grievously wounded and gasps for its last breath.")

func test_flee_request_has_its_own_line() -> void:
	var fight: Fight = Fight.new(_decision, _character, _monster)
	assert_str(fight.create_request(true).get_description()).is_equal("You look for a way to escape the Lurker.")

func test_summary_ends_with_outcome() -> void:
	var fight: Fight = Fight.new(_decision, _character, _monster)
	_apply(fight, [1, 1, 2, 2, 7], 7, [3, 4, 5], 5, [Rules.d4, Rules.d6, Rules.d8, Rules.d10, Rules.d12], [Rules.d8, Rules.d8, Rules.d8], true)
	assert_str(fight.get_exchange_summary()).contains("You get away from the Lurker.")

func test_find_decision_owner_in_events() -> void:
	var base: AdventurePage = load("res://adventure/adventures/locations/swamp/temple_ruin.tres")
	var ambush: AdventurePage = load("res://adventure/adventures/locations/swamp/events/lurker_ambush.tres")
	for ambush_decision: AdventureDecision in ambush._decisions:
		assert_object(base.find_decision_owner(ambush_decision)).is_same(ambush)
	assert_object(base.find_decision_owner(AdventureDecision.new())).is_null()

func _apply(
	fight: Fight,
	player_results: Array[int], player_guts: int,
	monster_results: Array[int], monster_guts: int,
	player_types: Array[DieType] = [Rules.d4, Rules.d6, Rules.d8, Rules.d10, Rules.d12],
	monster_types: Array[DieType] = [Rules.d8, Rules.d8, Rules.d8],
	fleeing: bool = false,
) -> void:
	var player: FightSide = FightSide.new(GUTS, _dice(player_types, player_results), _scores(player_guts), [], fleeing)
	var opponent: FightSide = FightSide.new(GUTS, _dice(monster_types, monster_results), _scores(monster_guts))
	var exchange: FightExchange = FightExchange.new(player, opponent)
	fight.apply_exchange(exchange, player.lost_breath_dice)

## Injuries are relative to the Lurker's authored Guts
func _lurker_guts() -> int:
	return _monster.monster_profile.attribute_scores[GUTS]

func _scores(score: int) -> Dictionary[CharacterAttribute, int]:
	return {GUTS: score, BLOOD: score, Rules.INTELLIGENCE: score}

func _dice(die_types: Array[DieType], results: Array[int]) -> Array[Die]:
	assert(die_types.size() == results.size())
	var dice: Array[Die] = []
	for index: int in die_types.size(): dice.append(Die.new(die_types[index], results[index]))
	return dice
