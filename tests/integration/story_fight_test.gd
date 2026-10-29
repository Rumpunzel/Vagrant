extends GdUnitTestSuite

## Plays a fight through the real Story scene: fight/flee choices, exchange pages, outcome transitions.

const MAX_EXCHANGES: int = 40

var _story: Story
var _fight_page: AdventurePage
var _outcome_pages: Dictionary[AdventurePage, Fight.Outcome]

func before_test() -> void:
	var decision: AdventureFightDecision = AdventureFightDecision.new()
	decision.description = "Fight!"
	decision.flee_description = "Wun away!"
	decision.enemies = [TestMonsters.cutthroat()] as Array[MonsterProfile]
	_outcome_pages = {}
	for outcome: Fight.Outcome in [Fight.Outcome.WON, Fight.Outcome.LOST, Fight.Outcome.DRAW, Fight.Outcome.FLED]:
		var page: AdventurePage = AdventurePage.new()
		page.title = Fight.Outcome.find_key(outcome)
		_outcome_pages[page] = outcome
	decision.transition = _outcome_pages.find_key(Fight.Outcome.WON)
	decision.failure_transition = _outcome_pages.find_key(Fight.Outcome.LOST)
	decision.draw_transition = _outcome_pages.find_key(Fight.Outcome.DRAW)
	decision.flee_transition = _outcome_pages.find_key(Fight.Outcome.FLED)
	_fight_page = AdventurePage.new()
	_fight_page.title = "Ambush"
	_fight_page.decisions = [decision] as Array[AdventureDecision]
	var adventure: Adventure = Adventure.new()
	adventure.title = "Test"
	adventure.starting_page = _fight_page
	_story = auto_free(load("uid://db6oui711vqep").instantiate())  # story.tscn
	_story._reveal_delay = 0.01
	add_child(_story)
	var profile: CharacterProfile = TestCharacters.adventurer()
	assert_bool(profile.is_valid()).is_true()
	_story.start_adventure(adventure, profile)

## Page flips free old UI with queue_free and tweens; let them finish so gdUnit does not report them as orphans
func after_test() -> void:
	await await_millis(500)

func test_fight_page_offers_fight_and_flee() -> void:
	var choices: Array[StoryChoice] = _story._current_story_page.choices
	assert_int(choices.size()).is_equal(2)
	assert_bool(choices[0] is StoryFightDecision and not (choices[0] as StoryFightDecision).fleeing).is_true()
	assert_bool(choices[1] is StoryFightDecision and (choices[1] as StoryFightDecision).fleeing).is_true()
	assert_str(choices[0].get_description()).is_equal("Fight!")
	assert_str(choices[1].get_description()).is_equal("Wun away!")
	assert_object((choices[1] as StoryFightDecision).get_dice_request().attribute).is_same(Rules.AGILITY)

func test_fighting_ends_on_an_outcome_page() -> void:
	var exchanges: int = 0
	while true:
		# Fight on, or roll the Guts save when an injury overwhelms the player
		var choice: StoryChoice = _story._current_story_page.choices[0]
		var fight: Fight = (choice as StoryFightDecision).fight if choice is StoryFightDecision else _story._current_story_page.fight
		await _pick(choice)
		exchanges += 1
		var page: StoryPage = _story._current_story_page
		if page.is_fight_exchange():
			assert_object(page.fight).is_same(fight)
			assert_bool(fight.is_ongoing()).is_true()
			assert_str(page.page_title).is_equal(fight.get_title())
			assert_int(exchanges).is_less(MAX_EXCHANGES)
			continue
		assert_bool(fight.is_ongoing()).is_false()
		assert_bool(_outcome_pages.has(page.adventure_page)).is_true()
		assert_int(_outcome_pages[page.adventure_page]).is_equal(fight.outcome)
		break
	# Exchange pages are not logged as visits
	assert_int(_story._page_log[_fight_page].size()).is_equal(1)
	assert_int(_story._page_stack.size()).is_equal(1)

func test_fleeing_leaves_after_one_exchange() -> void:
	var choice: StoryFightDecision = _story._current_story_page.choices[1]
	await _pick(choice)
	# A hit that overwhelms calls for the Guts save first; collapsing while fleeing loses
	if _story._current_story_page.choices[0] is StorySaveDecision: await _pick(_story._current_story_page.choices[0])
	var expected: Fight.Outcome = Fight.Outcome.LOST if choice.fight.incapacitated.get(choice.fight.player, false) else Fight.Outcome.FLED
	assert_object(_story._current_story_page.adventure_page).is_same(_outcome_pages.find_key(expected))
	assert_int(choice.fight.outcome).is_equal(expected)

func test_resting_is_disabled_while_fighting() -> void:
	var mechanics: Mechanics = _story.get_node("PanelContainer/MarginContainer/HSplitContainer/HBoxContainer/Mechanics")
	assert_bool(mechanics._catch_breath_button.disabled).is_true()
	assert_bool(mechanics._make_camp_button.disabled).is_true()
	# Fleeing ends the fight: the outcome page lets the party rest again
	await _pick(_story._current_story_page.choices[1] as StoryFightDecision)
	if _story._current_story_page.choices[0] is StorySaveDecision: await _pick(_story._current_story_page.choices[0])
	assert_bool(_story._current_story_page.is_fighting()).is_false()
	assert_bool(mechanics._make_camp_button.disabled).is_false()
	assert_bool(mechanics._catch_breath_button.disabled).is_equal(not mechanics._party.characters.values().any(func(character: Character) -> bool: return character.can_catch_breath(null)) and not mechanics._can_catch_breath)

func test_overwhelming_injury_asks_for_a_guts_save() -> void:
	var choice: StoryFightDecision = _story._current_story_page.choices[0]
	var fight: Fight = choice.fight
	# Guts 7 - 5 - 3 = -1: the exchange's 1 vs 4 overwhelms the player
	_story._protagonist.suffer_injury(Injury.new(5))
	var result: FightResult = choice.get_dice_request().roll()
	var player: FightSide = FightSide.new(Rules.STRENGTH, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(7))
	result.exchange = FightExchange.new(player, FightSide.new(Rules.STRENGTH, FightTestDice.dice([Rules.d8], [4]), FightTestDice.scores(7)))
	fight.start_exchange_from(result)
	while not (fight.get_current_step() is IncapacitationStep and fight.get_current_step().is_first()): fight.advance()
	# Normally reached by the exchange playing out step by step
	_story._ask_for_incapacitation_save(fight, fight.get_current_step() as IncapacitationStep, result, choice)
	var page: StoryPage = _story._current_story_page
	assert_bool(page.is_fighting()).is_true()
	assert_str(page.description).contains("hold on to your senses")
	var save: StorySaveDecision = page.choices[0]
	assert_object(save.get_dice_request().attribute).is_same(Rules.STRENGTH)
	assert_int(save.get_dice_request().get_difficulty()).is_equal(8)
	await _pick(save)
	assert_bool(fight.incapacitated.get(fight.player, false)).is_equal(not save.get_dice_result().is_success())
	assert_str(fight.get_exchange_summary()).contains("Everything goes dark." if fight.incapacitated.get(fight.player, false) else "You keep your senses.")
	# The exchange went on after the save: collapsing loses the fight
	if fight.incapacitated.get(fight.player, false): assert_object(_story._current_story_page.adventure_page).is_same(_outcome_pages.find_key(Fight.Outcome.LOST))

func test_giving_in_loses_without_rolling() -> void:
	var choice: StoryFightDecision = _story._current_story_page.choices[0]
	var fight: Fight = choice.fight
	_story._protagonist.suffer_injury(Injury.new(5))
	var result: FightResult = choice.get_dice_request().roll()
	var player: FightSide = FightSide.new(Rules.STRENGTH, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(7))
	result.exchange = FightExchange.new(player, FightSide.new(Rules.STRENGTH, FightTestDice.dice([Rules.d8], [4]), FightTestDice.scores(7)))
	fight.start_exchange_from(result)
	while not (fight.get_current_step() is IncapacitationStep and fight.get_current_step().is_first()): fight.advance()
	_story._ask_for_incapacitation_save(fight, fight.get_current_step() as IncapacitationStep, result, choice)
	var give_in: StoryChoice = _story._current_story_page.choices[1]
	assert_str(give_in.get_description()).is_equal("Give in.")
	var breath_before: Dictionary[DieType, int] = _story._protagonist.breath_dice.duplicate()
	await _pick(give_in)
	assert_bool(fight.incapacitated.get(fight.player, false)).is_true()
	assert_dict(_story._protagonist.breath_dice).is_equal(breath_before)
	assert_object(_story._current_story_page.adventure_page).is_same(_outcome_pages.find_key(Fight.Outcome.LOST))

func test_a_weapon_die_beyond_guts_can_be_forced() -> void:
	var choice: StoryFightDecision = _story._current_story_page.choices[0]
	var fight: Fight = choice.fight
	var sword: Weapon = Weapon.create(WeaponProfile.create("Sword", Rules.d10))
	_story._protagonist.weapons = [sword] as Array[Weapon]
	choice.get_dice_request().selected_weapon = sword
	var result: FightResult = choice.get_dice_request().roll()
	# Guts 7: forcing the Sword's 9 costs 2 threat; 4 − 2 vs 1 still keeps the Cutthroat from hurting the player
	var player: FightSide = FightSide.new(Rules.STRENGTH, FightTestDice.dice([Rules.d4], [4]), FightTestDice.scores(7), FightTestDice.dice([Rules.d10], [9]))
	player.weapon = sword
	result.exchange = FightExchange.new(player, FightSide.new(Rules.STRENGTH, FightTestDice.dice([Rules.d8], [1]), FightTestDice.scores(7)))
	fight.start_exchange_from(result)
	_story._play_fight_step(fight, result, choice)
	var panel: FightCommitPanel = _get_commit_panel()
	var options: Array[Node] = panel.find_children("*", "CheckBox", true, false)
	assert_array(options.map(func(option: CheckBox) -> String: return option.text)).is_equal(["Force the 9: −2 threat, marks the 9 and 10 (8 of 10 faces left).", "Hold back."])
	# Nothing is free, so holding back is what the panel starts on
	assert_bool((options[1] as CheckBox).button_pressed).is_true()
	(options[0] as CheckBox).button_pressed = true
	await _strike(panel)
	assert_array(sword.marked_faces).is_equal([9, 10])
	assert_int(fight.get_last_exchange().second.injury_taken).is_greater(8)

func test_the_shield_is_raised_by_default_when_free() -> void:
	var choice: StoryFightDecision = _story._current_story_page.choices[0]
	var fight: Fight = choice.fight
	var buckler: Shield = Shield.create(ShieldProfile.create("Buckler", Rules.d6))
	_story._protagonist.shields = [buckler] as Array[Shield]
	var result: FightResult = choice.get_dice_request().roll()
	# The Buckler's 3 threatens: 3 vs 7, so the Cutthroat's vantage of 4 comes at the player and the 3 takes 3 off
	var player: FightSide = FightSide.new(Rules.STRENGTH, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(7))
	player.shield_dice = FightTestDice.dice([Rules.d6], [3])
	result.exchange = FightExchange.new(player, FightSide.new(Rules.STRENGTH, FightTestDice.dice([Rules.d8], [7]), FightTestDice.scores(7)))
	player.shield = buckler
	fight.start_exchange_from(result)
	_story._play_fight_step(fight, result, choice)
	var panel: FightCommitPanel = _get_commit_panel()
	var switch: CheckButton = panel.find_children("*", "CheckButton", true, false)[0]
	assert_str(switch.text).is_equal("Raise your Buckler.")
	assert_bool(switch.button_pressed).is_true()
	await _strike(panel)
	assert_array(buckler.marked_faces).is_equal([3])
	assert_int(fight.get_last_exchange().first.injury_taken).is_equal(1)

func test_the_player_picks_which_armour_takes_a_blow() -> void:
	var choice: StoryFightDecision = _story._current_story_page.choices[0]
	var fight: Fight = choice.fight
	var helmet: Armor = Armor.create(ArmorProfile.create("Helmet", [5, 10] as Array[int]))
	var coif: Armor = Armor.create(ArmorProfile.create("Coif", [5] as Array[int]))
	_story._protagonist.armor = [helmet, coif] as Array[Armor]
	var result: FightResult = choice.get_dice_request().roll()
	# The Cutthroat wins the threat and its knife comes up 5, which both pieces block
	var player: FightSide = FightSide.new(Rules.STRENGTH, FightTestDice.dice([Rules.d4], [1]), FightTestDice.scores(7))
	player.armor_blocks = [5, 10] as Array[int]
	result.exchange = FightExchange.new(player, FightSide.new(Rules.STRENGTH, FightTestDice.dice([Rules.d8], [3]), FightTestDice.scores(7), FightTestDice.weapon(Rules.d8, 5)))
	fight.start_exchange_from(result)
	while not (fight.get_current_step() is ArmorStep and fight.get_current_step().is_player(fight)): fight.advance()
	_story._ask_for_armor(fight, fight.get_current_step() as ArmorStep, result, choice)
	var page: StoryPage = _story._current_story_page
	assert_array(page.choices.map(func(option: StoryChoice) -> String: return option.get_description())).is_equal(["Let your Helmet take it: the 5 gets marked.", "Let your Coif take it: the 5 gets marked."])
	await _pick(page.choices[1])
	assert_array(coif.marked_faces).is_equal([5])
	assert_array(helmet.marked_faces).is_empty()

func test_monster_lives_in_story() -> void:
	var choice: StoryFightDecision = _story._current_story_page.choices[0]
	assert_object((choice.fight.second as Monster).get_parent()).is_same(_story._monsters)
	assert_object((choice.fight.second as Monster).spawned_from).is_same(_fight_page)

## Releasing the skip key, like a player would, so typed-out text does not slow the test down
func _skip_typing() -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = KEY_SPACE
	event.pressed = false
	Input.parse_input_event(event)

## Chooses and rolls like the UI does, then waits for the next page
func _pick(choice: StoryChoice) -> void:
	var page: StoryPage = _story._current_story_page
	choice.chose()
	if choice.is_dice_choice(): choice.roll()
	await _wait_for_page_after(page)

## Strikes as committed in [param panel], then waits for the page after the exchange
func _strike(panel: FightCommitPanel) -> void:
	var page: StoryPage = _story._current_story_page
	panel.strike()
	await _wait_for_page_after(page)

func _get_commit_panel() -> FightCommitPanel:
	var panels: Array[Node] = get_tree().root.find_children("*", "VBoxContainer", true, false).filter(func(node: Node) -> bool: return node is FightCommitPanel)
	assert_int(panels.size()).is_equal(1)
	return panels[0]

func _wait_for_page_after(page: StoryPage) -> void:
	var waited: int = 0
	while _story._current_story_page == page:
		_skip_typing()
		await await_millis(10)
		waited += 10
		assert_int(waited).is_less(5000)
		if waited >= 5000: return
