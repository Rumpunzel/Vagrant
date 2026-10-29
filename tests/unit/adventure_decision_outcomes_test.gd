extends GdUnitTestSuite

## The ways decisions end, which the game and the adventure editor both go by.

func test_plain_decision_has_one_outcome() -> void:
	var page: AdventurePage = AdventurePage.new()
	var decision: AdventureDecision = AdventureDecision.new()
	decision.transition = page
	decision.consequences = [AdventureInjuryConsequence.new()] as Array[AdventureConsequence]
	var outcomes: Array[AdventureDecision.Outcome] = decision.get_outcomes()
	assert_int(outcomes.size()).is_equal(1)
	assert_str(outcomes[0].name).is_empty()
	assert_object(decision.get_reference(outcomes[0])).is_same(page)
	assert_array(decision.get_consequences_of(outcomes[0])).is_equal(decision.consequences)
	assert_array(decision.get_page_references()).contains_exactly([page])

func test_save_succeeds_or_fails() -> void:
	var success: AdventurePage = AdventurePage.new()
	var failure: AdventurePage = AdventurePage.new()
	var save: AdventureSaveDecision = AdventureSaveDecision.new()
	save.transition = success
	save.failure_transition = failure
	save.failure_consequences = [AdventureInjuryConsequence.new()] as Array[AdventureConsequence]
	assert_array(save.get_outcomes().map(func(outcome: AdventureDecision.Outcome) -> String: return outcome.name)).contains_exactly(["Success", "Failure"])
	assert_object(save.get_reference(save.get_outcome(true))).is_same(success)
	assert_object(save.get_reference(save.get_outcome(false))).is_same(failure)
	assert_array(save.get_consequences_of(save.get_outcome(true))).is_empty()
	assert_int(save.get_consequences_of(save.get_outcome(false)).size()).is_equal(1)

func test_fight_outcomes_follow_how_the_fight_ended() -> void:
	var fight: AdventureFightDecision = AdventureFightDecision.new()
	var pages: Array[AdventurePage] = [AdventurePage.new(), AdventurePage.new(), AdventurePage.new(), AdventurePage.new()]
	fight.transition = pages[0]
	fight.failure_transition = pages[1]
	fight.flee_transition = pages[2]
	fight.draw_transition = pages[3]
	assert_array(fight.get_outcomes().map(func(outcome: AdventureDecision.Outcome) -> String: return outcome.name)).contains_exactly(["Won", "Lost", "Fled", "Draw"])
	var ended: Array[Fight.Outcome] = [Fight.Outcome.WON, Fight.Outcome.LOST, Fight.Outcome.FLED, Fight.Outcome.DRAW]
	for index: int in ended.size(): assert_object(fight.get_reference(fight.get_fight_outcome(ended[index]))).is_same(pages[index])
	# Fleeing and a draw do nothing but lead on
	assert_str(fight.get_fight_outcome(Fight.Outcome.FLED).consequences_property).is_empty()
	assert_array(fight.get_page_references()).contains_exactly(pages)
