extends GdUnitTestSuite

## Content check: the Lurker ambush in the swamp temple ruin is a real fight.
## Playing it through the Story scene: integration/lurker_ambush_story_test.gd

const LURKER: String = "uid://d3ytncs0be7oo"  # lurker.tres
const LURKER_AMBUSH: String = "uid://bxwqtk0p80o4g"  # lurker_ambush.tres
const ROCKY_SHORE: String = "uid://ycd6xhx346l6"  # rocky_shore.tres
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
	assert_str(lurker.weapons[0].name).is_equal("Knife")
	assert_object(lurker.weapons[0].die).is_same(Rules.d8)
	assert_array(lurker.weapon_modifiers).is_empty()
	assert_object(lurker.nature).is_same(Rules.STRENGTH)

func test_ambush_decision() -> void:
	var ambush: AdventurePage = load(LURKER_AMBUSH)
	assert_int(ambush._decisions.size()).is_equal(1)
	var decision: AdventureFightDecision = ambush._decisions[0]
	assert_str(decision.flee_description).is_equal("Wun away!")
	assert_object(decision.enemies[0]).is_same(load(LURKER))
	var references: Dictionary[Fight.Outcome, AdventurePageReference] = {
		Fight.Outcome.WON: decision.transition,
		Fight.Outcome.LOST: decision.failure_transition,
		Fight.Outcome.DRAW: decision.draw_transition,
		Fight.Outcome.FLED: decision.flee_transition,
	}
	for outcome: Fight.Outcome in references:
		var outcome_page: AdventurePage = references[outcome].get_adventure_page()
		assert_object(outcome_page).is_same(load(OUTCOME_PAGES[outcome]))
		assert_str(outcome_page._description).is_not_empty()
		# Each outcome page continues to the Rocky Shore
		assert_object(outcome_page._decisions[0].transition.get_adventure_page()).is_same(load(ROCKY_SHORE))
