extends GdUnitTestSuite

## Content check: the Lurker is an encounter at the swamp temple ruin; its ambush is a real fight, its monster tells whether it can fight, is beaten or dead.
## Playing it through the Story scene: integration/lurker_ambush_story_test.gd

const LURKER: String = "uid://d3ytncs0be7oo"  # lurker.tres
const LURKER_AMBUSH: String = "uid://bxwqtk0p80o4g"  # lurker_ambush.tres
const LURKER_ENCOUNTER: String = "uid://c16ehct0w6n48"  # encounters/lurker/lurker.tres
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
	var ambush: AdventureEvent = load(LURKER_AMBUSH)
	# First the water stirs: only "Continue." leads on, into the fight
	assert_int(ambush.decisions.size()).is_equal(1)
	assert_str(ambush.decisions[0].description).is_equal("Continue.")
	assert_str(ambush.title).is_empty()
	var strikes: AdventurePage = ambush.decisions[0].transition as AdventurePage
	assert_str(strikes.title).is_equal("Lurker Ambush")
	var decision: AdventureFightDecision = strikes.decisions[0]
	assert_str(decision.flee_description).is_equal("Wun away!")
	# Its own encounter's monster fights
	assert_str(decision.encounter).is_empty()
	assert_array(decision.enemies).is_empty()
	assert_object((load(LURKER_ENCOUNTER) as AdventureEncounter).profile).is_same(load(LURKER))
	# Winning beats its monster by itself: no consequence needed
	assert_array(decision.consequences).is_empty()
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
	var ambush: AdventureEvent = load(LURKER_AMBUSH)
	var condition: AdventureMonsterCondition = ambush.conditions[0]
	assert_str(condition.encounter).is_empty()
	assert_int(condition.state).is_equal(AdventureMonsterCondition.State.CAN_FIGHT)
	# And only by chance
	var chance: AdventureChanceCondition = ambush.conditions[1]
	assert_str(chance.describe()).is_equal("1 in 2 chance")

func test_won_event_offers_to_kill_the_beaten_lurker() -> void:
	var won: AdventureEvent = load(OUTCOME_PAGES[Fight.Outcome.WON])
	assert_int(won.exclusivity).is_equal(0)
	assert_int((won.conditions[0] as AdventureMonsterCondition).state).is_equal(AdventureMonsterCondition.State.BEATEN)
	var kill: AdventureDecision = won.decisions[0]
	assert_str(kill.description).is_equal("Kill the Lurker.")
	assert_object(kill.consequences[0]).is_instanceof(AdventureKillConsequence)
	assert_object(kill.transition).is_instanceof(AdventureHostReference)

func test_the_encounter_shows_the_ambush_or_the_beaten_lurker() -> void:
	var lurker: AdventureEncounter = load(LURKER_ENCOUNTER)
	assert_array(lurker.events).contains_exactly([load(LURKER_AMBUSH), load(OUTCOME_PAGES[Fight.Outcome.WON])])
	assert_int(lurker.pick).is_equal(AdventureEventScenario.Pick.FIRST)
	assert_array(lurker.get_places()).contains_exactly([load(TEMPLE_RUIN)])
	assert_array(lurker.tracks).is_empty()
	assert_array((load(TEMPLE_RUIN) as AdventureLocation).get_own_events()).is_empty()
	var story: Story = auto_free(Story.new())
	story._monsters = auto_free(Monsters.new())
	story.chance_roller = func(_condition: AdventureChanceCondition) -> bool: return true
	story.world = StoryWorld.new([lurker] as Array[AdventureEncounter])
	var temple: AdventureLocation = load(TEMPLE_RUIN)
	assert_array(temple.get_events(story)).contains_exactly([load(LURKER_AMBUSH)])
	var monster: Monster = story.get_monster(lurker, lurker.profile as MonsterProfile)
	monster.incapacitated = true
	assert_array(temple.get_events(story)).contains_exactly([load(OUTCOME_PAGES[Fight.Outcome.WON])])
	story._encounter = lurker
	(load(OUTCOME_PAGES[Fight.Outcome.WON]) as AdventureEvent).decisions[0].consequences[0].resolve(story, 0)
	assert_bool(monster.dead).is_true()
	assert_array(temple.get_events(story)).is_empty()
