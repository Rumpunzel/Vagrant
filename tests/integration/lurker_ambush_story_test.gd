extends GdUnitTestSuite

## Plays the Lurker ambush through the real Story scene.

const TEMPLE_RUIN: String = "uid://cs40ge42lw0ry"  # temple_ruin.tres
const LURKER_AMBUSH: String = "uid://bxwqtk0p80o4g"  # lurker_ambush.tres
const OUTCOME_PAGES: Dictionary[Fight.Outcome, String] = {
	Fight.Outcome.WON: "uid://m4wl5ad8o0i7",  # lurker_ambush_won.tres
	Fight.Outcome.LOST: "uid://dgfjjbm210jot",  # lurker_ambush_lost.tres
	Fight.Outcome.DRAW: "uid://dsfrbfoig3deo",  # lurker_ambush_draw.tres
	Fight.Outcome.FLED: "uid://qcl0jfm16ys8",  # lurker_ambush_fled.tres
}

func after_test() -> void:
	await await_millis(500)

func test_flee_from_ambush_in_story() -> void:
	# Ends on the ambush's flee page
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = load(TEMPLE_RUIN)
	var story: Story = auto_free(load("uid://db6oui711vqep").instantiate())  # story.tscn
	story._reveal_delay = 0.01
	add_child(story)
	story.start_adventure(adventure, TestCharacters.adventurer())
	var fight_choices: Array[StoryFightDecision] = []
	for choice: StoryChoice in story._current_story_page.choices:
		if choice is StoryFightDecision: fight_choices.append(choice)
	assert_int(fight_choices.size()).is_equal(2)
	var flee: StoryFightDecision = fight_choices[1]
	assert_str(flee.get_description()).is_equal("Wun away!")
	# The Lurker belongs to the ambush event, not the temple ruin
	assert_object((flee.fight.second as Monster).spawned_from).is_same(load(LURKER_AMBUSH))
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
