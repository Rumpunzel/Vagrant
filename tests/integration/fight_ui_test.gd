extends GdUnitTestSuite

## Fight input UI (BreathDiceSelection) inside the real Story scene.

const STORY: String = "uid://db6oui711vqep"  # story.tscn
const DORIAN: String = "uid://73nsysikxf7j"  # dorian.tres

var _story: Story

func _start(weapon_dice: Array[DieType]) -> void:
	var decision: AdventureFightDecision = AdventureFightDecision.new()
	decision.description = "Fight!"
	decision.enemies = [load("uid://d3ytncs0be7oo")] as Array[MonsterProfile]  # lurker.tres
	var end_page: AdventurePage = AdventurePage.new()
	end_page._title = "End"
	decision.transition = end_page
	decision.failure_transition = end_page
	decision.draw_transition = end_page
	decision.flee_transition = end_page
	var page: AdventurePage = AdventurePage.new()
	page._decisions = [decision] as Array[AdventureDecision]
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = page
	_story = auto_free(load(STORY).instantiate())
	_story._reveal_delay = 0.01
	add_child(_story)
	var profile: CharacterProfile = (load(DORIAN) as CharacterProfile).duplicate(true)
	profile.weapon_dice = weapon_dice
	_story.start_adventure(adventure, profile)

## Collapsible tweens and page fades; let them finish so gdUnit does not report them as orphans
func after_test() -> void:
	await await_millis(500)

func test_armed_fight_offers_stance_and_nerves_target() -> void:
	_start([Rules.d10] as Array[DieType])
	var request: FightRequest = await _choose(0)
	var selection: BreathDiceSelection = _selection()
	assert_bool(request.has_stance_choice()).is_true()
	assert_bool(selection._stance_selection.attribute_selected.is_connected(request.set_attribute)).is_true()
	assert_object(request.nerves_target).is_same(Rules.STRENGTH)
	request.attribute = Rules.STRENGTH
	assert_bool(selection._nerves_target_selection.visible).is_false()
	request.attribute = Rules.INTELLIGENCE
	assert_bool(selection._nerves_target_selection.visible).is_true()
	assert_object(selection._stance_selection.get_panel().attribute).is_same(Rules.INTELLIGENCE)
	selection._nerves_target_selection.set_selected_attribute(Rules.AGILITY)
	assert_object(request.nerves_target).is_same(Rules.AGILITY)

func test_flee_has_no_stance_and_switching_cleans_up() -> void:
	_start([Rules.d10] as Array[DieType])
	var fight_request: FightRequest = await _choose(0)
	var flee_request: FightRequest = await _choose(1)
	var selection: BreathDiceSelection = _selection()
	assert_bool(flee_request.has_stance_choice()).is_false()
	assert_object(flee_request.attribute).is_same(Rules.AGILITY)
	assert_bool(selection._nerves_target_selection.visible).is_false()
	# Nothing of the abandoned Fight request is still wired to the UI
	assert_bool(fight_request.rolled.is_connected(selection._on_fight_rolled)).is_false()
	assert_bool(selection._stance_selection.attribute_selected.is_connected(fight_request.set_attribute)).is_false()
	assert_bool(selection._nerves_target_selection.attribute_selected.is_connected(fight_request.set_nerves_target)).is_false()
	assert_bool(flee_request.rolled.is_connected(selection._on_fight_rolled)).is_true()

func test_unarmed_fight_has_no_stance() -> void:
	_start([] as Array[DieType])
	var request: FightRequest = await _choose(0)
	assert_bool(request.has_stance_choice()).is_false()
	assert_object(request.attribute).is_same(Rules.STRENGTH)
	assert_bool(_selection()._stance_selection.attribute_selected.is_connected(request.set_attribute)).is_false()

func test_dice_log_shows_fight_result() -> void:
	_start([Rules.d10] as Array[DieType])
	await _choose(0)
	var selection: BreathDiceSelection = _selection()
	var entry: StoryEntry = _story._story_book._current_page_entry
	var choice: StoryFightDecision = _story._current_story_page.choices[0]
	choice.roll()
	await await_millis(1000)
	var result: FightResult = choice.get_dice_result()
	var text: String = _final_text(selection._dice_log_save_result_entry._entry)
	assert_str(text).contains("%d[/color] vs %d" % [result.get_player_side().threat, result.get_opponent_side().threat])
	var player_injury: int = result.get_player_side().injury_taken
	var opponent_injury: int = result.get_opponent_side().injury_taken
	assert_bool(text.contains("Lurker %s" % Injury.to_bbcode(opponent_injury))).is_equal(opponent_injury > 0)
	assert_bool(text.contains("you %s" % Injury.to_bbcode(player_injury))).is_equal(player_injury > 0)
	assert_str(text).not_contains("−0")
	# Injuries and the exchange summary sit below this roll, in the same entry
	var injury_count: int = int(player_injury > 0) + int(opponent_injury > 0)
	assert_int(entry._injuries.get_child_count()).is_equal(injury_count)
	assert_bool(entry._injuries.visible).is_equal(injury_count > 0)
	assert_bool(entry._outcome.visible).is_true()
	assert_str(_final_text(entry._outcome)).contains("You threaten with")

func test_next_exchange_waits_for_summary_typing() -> void:
	_start([Rules.d10] as Array[DieType])
	await _choose(0)
	var page: StoryPage = _story._current_story_page
	var entry: StoryEntry = _story._story_book._current_page_entry
	(page.choices[0] as StoryFightDecision).roll()
	var waited: int = 0
	while _story._current_story_page == page and waited < 10000:
		# While the summary is still being typed, the next page must not appear
		if entry._outcome.visible and entry._outcome.visible_ratio < 1.0: assert_object(_story._current_story_page).is_same(page)
		await await_millis(5)
		waited += 5
	assert_object(_story._current_story_page).is_not_same(page)
	assert_float(entry._outcome.visible_ratio).is_equal(1.0)

func test_dice_selection_shows_monster_threat() -> void:
	_start([Rules.d10] as Array[DieType])
	var request: FightRequest = await _choose(0)
	assert_str(request.get_description()).is_equal("The Lurker threatens you with %s." % Fight.describe_attribute(Rules.STRENGTH))
	assert_str(_final_text(_selection()._description)).is_equal(request.get_description())

func test_dice_log_shows_save_result() -> void:
	var decision: AdventureSaveDecision = AdventureSaveDecision.new()
	decision.description = "Jump"
	decision.attribute = Rules.AGILITY
	decision.difficulty = 1
	var end_page: AdventurePage = AdventurePage.new()
	end_page._title = "End"
	decision.transition = end_page
	decision.failure_transition = end_page
	var page: AdventurePage = AdventurePage.new()
	page._decisions = [decision] as Array[AdventureDecision]
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = page
	_story = auto_free(load(STORY).instantiate())
	_story._reveal_delay = 0.01
	add_child(_story)
	_story.start_adventure(adventure, (load(DORIAN) as CharacterProfile).duplicate(true))
	var choice: StoryChoice = _story._current_story_page.choices[0]
	choice.chose()
	await await_millis(50)
	var selection: BreathDiceSelection = _selection()
	choice.roll()
	await await_millis(1000)
	var text: String = _final_text(selection._dice_log_save_result_entry._entry)
	assert_str(text).not_contains("Rolling...")
	assert_str(text).contains("→")

## TypingLabel may still be typing; its target text is what will be shown
func _final_text(label: TypingLabel) -> String:
	return label._text_to_type if not label._text_to_type.is_empty() else label.text

func _choose(index: int) -> FightRequest:
	var choice: StoryFightDecision = _story._current_story_page.choices[index]
	choice.chose()
	await await_millis(50)
	return choice.get_dice_request()

func _selection() -> BreathDiceSelection:
	var entry: StoryEntry = _story._story_book._current_page_entry
	return entry._breath_dice_selection
