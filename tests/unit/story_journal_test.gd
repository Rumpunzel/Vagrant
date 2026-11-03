extends GdUnitTestSuite

## The journal keeps what happened in order, as plain values and resource IDs, and counts visits and decisions.

var _journal: StoryJournal

func before_test() -> void:
	_journal = StoryJournal.new()

func test_counts_visits_and_decisions() -> void:
	var page: AdventurePage = AdventurePage.new()
	var decision: AdventureDecision = AdventureDecision.new()
	assert_int(_journal.get_times_entered(page)).is_equal(0)
	_journal.enter(page)
	_journal.enter(page)
	_journal.choose(decision)
	assert_int(_journal.get_times_entered(page)).is_equal(2)
	assert_int(_journal.get_times_made(decision)).is_equal(1)
	assert_array(_journal.entries.map(func(entry: Dictionary) -> String: return entry.type)).contains_exactly(["enter", "enter", "choose"])

func test_entries_are_plain_values() -> void:
	_journal.start(Adventure.new(), 42)
	_journal.enter(AdventurePage.new())
	var json: String = JSON.stringify(_journal.entries)
	assert_array(JSON.parse_string(json) as Array).has_size(2)
	assert_dict(_journal.entries[0]).is_equal({type = "start", adventure = "", seed = 42})

func test_watches_the_world() -> void:
	var world: StoryWorld = StoryWorld.new()
	_journal.watch(world)
	var encounter: AdventureEncounter = AdventureEncounter.new()
	world.set_stage(encounter, "Mood", "angry")
	world.move(encounter, [AdventureLocation.new()] as Array[AdventureLocation])
	assert_dict(_journal.entries[0]).is_equal({type = "stage", subject = "", track = "Mood", stage = "angry"})
	assert_dict(_journal.entries[1]).is_equal({type = "move", encounter = "", places = [""]})

func test_story_writes_chance_once_per_arrival() -> void:
	var story: Story = auto_free(Story.new())
	story.chance_roller = func(_condition: AdventureChanceCondition) -> bool: return true
	var condition: AdventureChanceCondition = AdventureChanceCondition.new()
	story.roll_chance(condition)
	story.roll_chance(condition)
	assert_array(story.journal.entries).has_size(1)
	assert_dict(story.journal.entries[0]).contains_key_value("came_up", true)

func test_watches_actors_once() -> void:
	var character: Character = auto_free(load("uid://bl0pdxri24fnh").instantiate())  # character.tscn
	add_child(character)
	character.character_profile = TestCharacters.adventurer()
	_journal.watch_actor(character)
	_journal.watch_actor(character)
	character.suffer_injury(Injury.new(2))
	character.lose_breath_dice([Die.new(Rules.d6, 6)] as Array[Die])
	assert_array(_journal.entries).has_size(2)
	assert_dict(_journal.entries[0]).is_equal({type = "injury", actor = "Tester", magnitude = 2, total = 2})
	assert_dict(_journal.entries[1]).contains_key_value("dice", ["d6"])

func test_plain_text() -> void:
	assert_str(StoryJournal._to_plain_text("[color=#fff]You[/color] take [img=20]res://wound.png[/img]2.")).is_equal("You take 2.")
