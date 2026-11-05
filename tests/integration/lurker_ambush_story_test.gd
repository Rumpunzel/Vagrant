extends GdUnitTestSuite

## Plays the Lurker ambush through the real Story scene.

const STORY_SCENE: PackedScene = preload("uid://db6oui711vqep")  # story.tscn
const TEMPLE_RUIN: String = "uid://cs40ge42lw0ry"  # temple_ruin.tres
const LURKER_AMBUSH: String = "uid://bxwqtk0p80o4g"  # lurker_ambush.tres
const LURKER_ENCOUNTER: String = "uid://c16ehct0w6n48"  # encounters/lurker/lurker.tres
const OUTCOME_PAGES: Dictionary[Fight.Outcome, String] = {
	Fight.Outcome.WON: "uid://m4wl5ad8o0i7",  # lurker_ambush_won.tres
	Fight.Outcome.LOST: "uid://dgfjjbm210jot",  # lurker_ambush_lost.tres
	Fight.Outcome.DRAW: "uid://dsfrbfoig3deo",  # lurker_ambush_draw.tres
	Fight.Outcome.FLED: "uid://qcl0jfm16ys8",  # lurker_ambush_fled.tres
}

func after_test() -> void:
	await await_millis(500)

func test_losing_the_ambush_leads_away_from_it() -> void:
	# Arriving from a path; without breath dice the fight is lost at once
	var path: AdventureLocation = AdventureLocation.new()
	path.title = "Path"
	var to_ruin: AdventureDecision = AdventureDecision.new()
	to_ruin.description = "To the ruin"
	to_ruin.transition = load(TEMPLE_RUIN)
	path.decisions = [to_ruin] as Array[AdventureDecision]
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = path
	adventure.encounters = [load(LURKER_ENCOUNTER)] as Array[AdventureEncounter]
	var story: Story = auto_free(STORY_SCENE.instantiate())
	story._reveal_delay = 0.01
	add_child(story)
	story.chance_roller = func(_condition: AdventureChanceCondition) -> bool: return true
	story.start_adventure(adventure, TestCharacters.adventurer())
	for die_type: DieType in story.get_protagonist().breath_dice.keys(): story.get_protagonist().breath_dice[die_type] = 0
	var visited: Array[AdventurePage] = []
	for _step: int in 4:
		var page: StoryPage = story._current_story_page
		page.choices[0].chose()
		await _until_left(story, page)
		visited.append(story._current_story_page.adventure_page)
	assert_array(visited).is_equal([load(TEMPLE_RUIN), (load(LURKER_AMBUSH) as AdventureEvent).decisions[0].transition, load(OUTCOME_PAGES[Fight.Outcome.LOST]), path])

func _until_left(story: Story, page: StoryPage) -> void:
	var waited: int = 0
	while story._current_story_page == page and waited < 5000:
		await await_millis(10)
		waited += 10

func test_flee_from_ambush_in_story() -> void:
	# Ends on the ambush's flee page
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = load(TEMPLE_RUIN)
	adventure.encounters = [load(LURKER_ENCOUNTER)] as Array[AdventureEncounter]
	var story: Story = auto_free(STORY_SCENE.instantiate())
	story._reveal_delay = 0.01
	add_child(story)
	story.chance_roller = func(_condition: AdventureChanceCondition) -> bool: return true
	story.start_adventure(adventure, TestCharacters.adventurer())
	# The water stirs first; only "Continue." leads into the ambush
	var ripples: StoryPage = story._current_story_page
	assert_int(ripples.choices.size()).is_equal(1)
	ripples.choices[0].chose()
	var waited_for_ambush: int = 0
	while story._current_story_page == ripples and waited_for_ambush < 5000:
		await await_millis(10)
		waited_for_ambush += 10
	var fight_choices: Array[StoryFightDecision] = []
	for choice: StoryChoice in story._current_story_page.choices:
		if choice is StoryFightDecision: fight_choices.append(choice)
	assert_int(fight_choices.size()).is_equal(2)
	var flee: StoryFightDecision = fight_choices[1]
	assert_str(flee.get_description()).is_equal("Wun away!")
	# The Lurker belongs to its encounter, not the temple ruin or the ambush
	assert_object((flee.fight.second as Monster).spawned_from).is_same(load(LURKER_ENCOUNTER))
	flee.chose()
	flee.roll()
	var waited: int = 0
	while flee.fight.is_ongoing() or story._current_story_page.is_fighting():
		# A hit that overwhelms calls for the Guts save first; collapsing while fleeing loses
		var save: StoryChoice = story._current_story_page.choices[0] if not story._current_story_page.choices.is_empty() else null
		if save is StorySaveDecision and not save.is_chosen() and not story._current_dice_request:
			save.chose()
			save.roll()
		await await_millis(10)
		waited += 10
		if waited >= 10000: break
	var expected: Fight.Outcome = Fight.Outcome.LOST if flee.fight.incapacitated.get(flee.fight.player, false) else Fight.Outcome.FLED
	assert_object(story._current_story_page.adventure_page).is_same(load(OUTCOME_PAGES[expected]))
	assert_int(flee.fight.outcome).is_equal(expected)
	# Nothing before the temple ruin here: continuing goes back to it
	if expected == Fight.Outcome.FLED:
		var page: StoryPage = story._current_story_page
		page.choices[0].chose()
		waited = 0
		while story._current_story_page == page and waited < 5000:
			await await_millis(10)
			waited += 10
		assert_object(story._current_story_page.adventure_page).is_same(load(TEMPLE_RUIN))
