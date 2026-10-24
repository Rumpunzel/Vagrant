extends GdUnitTestSuite

## Content check: the Lurker ambush in the swamp temple ruin is a real fight.
## Playing it through the Story scene: integration/lurker_ambush_story_test.gd

const LURKER: String = "uid://d3ytncs0be7oo"  # lurker.tres
const LURKER_AMBUSH: String = "uid://bxwqtk0p80o4g"  # lurker_ambush.tres
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
	assert_int(ambush._decisions.size()).is_equal(1)
	var decision: AdventureFightDecision = ambush._decisions[0]
	assert_str(decision.flee_description).is_equal("Wun away!")
	assert_object(decision.enemies[0]).is_same(load(LURKER))
	# Winning goes back to the temple ruin, where the won event shows the beaten Lurker
	assert_object(decision.transition.get_adventure_page()).is_same(load(TEMPLE_RUIN))
	var references: Dictionary[Fight.Outcome, AdventurePageReference] = {
		Fight.Outcome.LOST: decision.failure_transition,
		Fight.Outcome.DRAW: decision.draw_transition,
		Fight.Outcome.FLED: decision.flee_transition,
	}
	for outcome: Fight.Outcome in references:
		var outcome_page: AdventurePage = references[outcome].get_adventure_page()
		assert_object(outcome_page).is_same(load(OUTCOME_PAGES[outcome]))
		assert_str(outcome_page._description).is_not_empty()
		# Back to the temple ruin; fleeing goes one page further back, to where the player came from
		var back: AdventureDecision = outcome_page._decisions[0]
		assert_object(back.transition).is_null()
		assert_int(back.back_steps).is_equal(2 if outcome == Fight.Outcome.FLED else 1)

func test_ambush_only_while_the_lurker_can_fight() -> void:
	var ambush: AdventurePage = load(LURKER_AMBUSH)
	var condition: AdventureMonsterCondition = ambush._conditions[0]
	assert_int(condition.state).is_equal(AdventureMonsterCondition.State.CAN_FIGHT)
	assert_object(condition.monster.monster).is_same(load(LURKER))
	# Its own Lurker: the ambush is the page that spawns it
	assert_object(condition.monster.spawned_by).is_null()

func test_won_event_offers_to_kill_the_beaten_lurker() -> void:
	var won: AdventurePage = load(OUTCOME_PAGES[Fight.Outcome.WON])
	assert_bool((load(TEMPLE_RUIN) as AdventurePage)._events.has(won)).is_true()
	assert_int(won._exclusivity).is_equal(0)
	var condition: AdventureMonsterCondition = won._conditions[0]
	assert_int(condition.state).is_equal(AdventureMonsterCondition.State.INCAPACITATED)
	assert_object(condition.monster.spawned_by.get_adventure_page()).is_same(load(LURKER_AMBUSH))
	var kill: AdventureDecision = won._decisions[0]
	assert_str(kill.description).is_equal("Kill the Lurker.")
	var consequence: AdventureKillMonsterConsequence = kill.consequences[0]
	assert_object(consequence.monster.spawned_by.get_adventure_page()).is_same(load(LURKER_AMBUSH))
	assert_object(kill.transition.get_adventure_page()).is_same(load(TEMPLE_RUIN))
