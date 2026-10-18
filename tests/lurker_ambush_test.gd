extends GdUnitTestSuite

## Content check: the Lurker ambush in the swamp temple ruin is a real fight.

const TEMPLE_RUIN: String = "res://adventure/adventures/locations/swamp/temple_ruin.tres"
const LURKER_AMBUSH: String = "res://adventure/adventures/locations/swamp/events/lurker_ambush.tres"
const ROCKY_SHORE: String = "res://adventure/adventures/locations/beach/rocky_shore.tres"
const OUTCOME_PAGES: Dictionary[Fight.Outcome, String] = {
	Fight.Outcome.WON: "res://adventure/adventures/locations/swamp/events/lurker_ambush_won.tres",
	Fight.Outcome.LOST: "res://adventure/adventures/locations/swamp/events/lurker_ambush_lost.tres",
	Fight.Outcome.DRAW: "res://adventure/adventures/locations/swamp/events/lurker_ambush_draw.tres",
	Fight.Outcome.FLED: "res://adventure/adventures/locations/swamp/events/lurker_ambush_fled.tres",
}

func after_test() -> void:
	await await_millis(500)

func test_lurker_profile() -> void:
	var lurker: MonsterProfile = load("res://characters/monsters/lurker.tres")
	assert_int(lurker.attribute_scores[Rules.STRENGTH]).is_equal(5)
	assert_array(lurker.weapon_dice).is_equal([Rules.d8])
	assert_object(lurker.nature).is_same(Rules.STRENGTH)

func test_ambush_decision() -> void:
	var ambush: AdventurePage = load(LURKER_AMBUSH)
	assert_int(ambush._decisions.size()).is_equal(1)
	var decision: AdventureFightDecision = ambush._decisions[0]
	assert_str(decision.flee_description).is_equal("Wun away!")
	assert_object(decision.enemies[0]).is_same(load("res://characters/monsters/lurker.tres"))
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

func test_flee_from_ambush_in_story() -> void:
	# Ends on the ambush's flee page
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = load(TEMPLE_RUIN)
	var story: Story = auto_free(load("res://story/story.tscn").instantiate())
	story._reveal_delay = 0.01
	add_child(story)
	story.start_adventure(adventure, (load("res://characters/dorian.tres") as CharacterProfile).duplicate(true))
	var fight_choices: Array[StoryFightDecision] = []
	for choice: StoryChoice in story._current_story_page.choices:
		if choice is StoryFightDecision: fight_choices.append(choice)
	assert_int(fight_choices.size()).is_equal(2)
	var flee: StoryFightDecision = fight_choices[1]
	assert_str(flee.get_description()).is_equal("Wun away!")
	# The Lurker belongs to the ambush event, not the temple ruin
	assert_object(flee.fight.monster.spawned_from).is_same(load(LURKER_AMBUSH))
	flee.chose()
	flee.roll()
	var waited: int = 0
	while story._current_story_page.adventure_page != load(OUTCOME_PAGES[Fight.Outcome.FLED]) and waited < 8000:
		await await_millis(10)
		waited += 10
	assert_object(story._current_story_page.adventure_page).is_same(load(OUTCOME_PAGES[Fight.Outcome.FLED]))
	assert_int(flee.fight.outcome).is_equal(Fight.Outcome.FLED)
