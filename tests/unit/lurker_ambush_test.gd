extends GdUnitTestSuite

## Content check: the Lurker ambush in the swamp temple ruin is a real fight, in a scenario that works on any page.
## Playing it through the Story scene: integration/lurker_ambush_story_test.gd

const LURKER: String = "uid://d3ytncs0be7oo"  # lurker.tres
const LURKER_AMBUSH: String = "uid://bxwqtk0p80o4g"  # lurker_ambush.tres
const LURKER_SCENARIO: String = "uid://c16ehct0w6n48"  # events/lurker.tres
const TEMPLE_RUIN: String = "uid://cs40ge42lw0ry"  # temple_ruin.tres
const OUTCOME_PAGES: Dictionary[Fight.Outcome, String] = {
	Fight.Outcome.WON: "uid://m4wl5ad8o0i7",  # lurker_ambush_won.tres
	Fight.Outcome.LOST: "uid://dgfjjbm210jot",  # lurker_ambush_lost.tres
	Fight.Outcome.DRAW: "uid://dsfrbfoig3deo",  # lurker_ambush_draw.tres
	Fight.Outcome.FLED: "uid://qcl0jfm16ys8",  # lurker_ambush_fled.tres
}

func test_lurker_profile() -> void:
	var lurker: MonsterProfile = load(LURKER)
	assert_int(lurker.attribute_scores[Rules.STRENGTH]).is_equal(5)
	assert_int(lurker.weapons.size()).is_equal(1)
	# The knife's own stats are checked in weapon_test.gd
	assert_object(lurker.weapons[0]).is_same(load("uid://dekvqsgavj6iv"))  # knife.tres
	assert_array(lurker.equipment_modifiers).is_empty()
	assert_object(lurker.attack).is_instanceof(NervesAttack)
	assert_object((lurker.attack as NervesAttack).target).is_same(Rules.AGILITY)

func test_ambush_decision() -> void:
	var ambush: AdventurePage = load(LURKER_AMBUSH)
	assert_int(ambush.decisions.size()).is_equal(1)
	var decision: AdventureFightDecision = ambush.decisions[0]
	assert_str(decision.flee_description).is_equal("Wun away!")
	assert_object(decision.enemies[0]).is_same(load(LURKER))
	# Winning goes back to wherever the ambush happened, where the scenario then shows the beaten Lurker
	assert_object(decision.transition).is_instanceof(AdventureHostReference)
	var references: Dictionary[Fight.Outcome, AdventurePageReference] = {
		Fight.Outcome.LOST: decision.failure_transition,
		Fight.Outcome.DRAW: decision.draw_transition,
		Fight.Outcome.FLED: decision.flee_transition,
	}
	for outcome: Fight.Outcome in references:
		var outcome_page: AdventurePage = references[outcome].get_adventure_page()
		assert_object(outcome_page).is_same(load(OUTCOME_PAGES[outcome]))
		assert_str(outcome_page.description).is_not_empty()
		# Fleeing and crawling away from a draw go to where the player was before the host; losing back to the host, by a decision or the automatic "Turn back."
		if outcome == Fight.Outcome.FLED or outcome == Fight.Outcome.DRAW:
			assert_object(outcome_page.decisions[0].transition).is_instanceof(AdventurePreviousLocationReference)
			continue
		if outcome_page.decisions.is_empty(): continue
		var back: AdventureDecision = outcome_page.decisions[0]
		assert_object(back.transition).is_null()
		assert_int(back.back_steps).is_equal(1)

func test_ambush_only_while_the_lurker_can_fight() -> void:
	var ambush: AdventurePage = load(LURKER_AMBUSH)
	var condition: AdventureMonsterCondition = ambush.conditions[0]
	assert_int(condition.state).is_equal(AdventureMonsterCondition.State.CAN_FIGHT)
	assert_object(condition.monster.monster).is_same(load(LURKER))
	# Its own Lurker: the ambush is the page that spawns it
	assert_object(condition.monster.spawned_by).is_null()

func test_won_event_offers_to_kill_the_beaten_lurker() -> void:
	var won: AdventurePage = load(OUTCOME_PAGES[Fight.Outcome.WON])
	assert_int(won.exclusivity).is_equal(0)
	var condition: AdventureMonsterCondition = won.conditions[0]
	assert_int(condition.state).is_equal(AdventureMonsterCondition.State.INCAPACITATED)
	assert_object(condition.monster.spawned_by.get_adventure_page()).is_same(load(LURKER_AMBUSH))
	var kill: AdventureDecision = won.decisions[0]
	assert_str(kill.description).is_equal("Kill the Lurker.")
	var consequence: AdventureKillMonsterConsequence = kill.consequences[0]
	assert_object(consequence.monster.spawned_by.get_adventure_page()).is_same(load(LURKER_AMBUSH))
	assert_object(kill.transition).is_instanceof(AdventureHostReference)

func test_scenario_shows_the_ambush_or_the_beaten_lurker() -> void:
	var scenario: AdventureEventScenario = load(LURKER_SCENARIO)
	assert_array((load(TEMPLE_RUIN) as AdventurePage).events).contains_exactly([scenario])
	# The ambush first: while the Lurker can fight, the beaten one isn't there
	assert_array(scenario.events).contains_exactly([load(LURKER_AMBUSH), load(OUTCOME_PAGES[Fight.Outcome.WON])])
	assert_array(scenario.conditions).is_empty()
	# One Lurker, wherever the scenario is placed
	assert_bool((load(LURKER_AMBUSH) as AdventurePage).generic).is_false()
