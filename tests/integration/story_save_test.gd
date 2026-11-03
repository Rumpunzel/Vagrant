extends GdUnitTestSuite

## A run is autosaved on each page and goes on from there: same page, same way back, same counts, same character.

const STORY: String = "uid://db6oui711vqep"  # story.tscn
const ADVENTURE_PATH: String = "user://story_save_test_adventure.tres"
const RUN: String = "story_save_test"

var _adventure: Adventure
var _story: Story

func before_test() -> void:
	var start: AdventureLocation = _location("Start")
	var next: AdventureLocation = _location("Next")
	start.first_description = "Never been here."
	var to_next: AdventureDecision = AdventureDecision.new()
	to_next.description = "Go on"
	to_next.transition = next
	start.decisions = [to_next] as Array[AdventureDecision]
	var back: AdventureDecision = AdventureDecision.new()
	back.description = "Go back"
	next.decisions = [back] as Array[AdventureDecision]
	var adventure: Adventure = Adventure.new()
	adventure.title = "Saved"
	adventure.starting_page = start
	ResourceSaver.save(adventure, ADVENTURE_PATH)
	_adventure = ResourceLoader.load(ADVENTURE_PATH, "", ResourceLoader.CACHE_MODE_REPLACE)
	# Not saved with it: a saved profile looks for portraits next to its file
	_adventure.protagonist = TestCharacters.adventurer()
	_story = _new_story()
	_story.run = RUN
	_story.start_adventure(_adventure, TestCharacters.adventurer())

func after_test() -> void:
	await await_millis(500)
	for path: String in [ADVENTURE_PATH, SaveGame.get_path_of(RUN)]: if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func test_autosaves_and_goes_on_from_there() -> void:
	_story.get_protagonist().suffer_injury(Injury.new(2))
	await _choose(_story, 0)
	await await_idle_frame()
	var save_game: SaveGame = SaveGame.read(RUN)
	assert_object(save_game).is_not_null()
	assert_array(save_game.get_problems()).is_empty()
	var start: AdventurePage = _adventure.starting_page
	var next: AdventurePage = start.decisions[0].transition as AdventurePage

	var loaded: Story = _new_story()
	loaded.restore(_adventure, RUN, save_game.story)
	assert_object(loaded._current_story_page.adventure_page).is_same(next)
	assert_int(loaded.get_how_often_page_has_been_entered(next)).is_equal(1)
	assert_int(loaded.get_how_often_page_has_been_entered(start)).is_equal(1)
	assert_int(loaded.get_how_often_decision_has_been_made(start.decisions[0])).is_equal(1)
	assert_int(loaded.get_protagonist().get_injury_total()).is_equal(2)
	assert_str(loaded.get_protagonist().get_actor_name()).is_equal("Tester")
	assert_str(loaded.journal.entries.back().type as String).is_equal("enter")
	# Back the way it came, and not there for the first time
	await _choose(loaded, 0)
	assert_object(loaded._current_story_page.adventure_page).is_same(start)
	assert_int(loaded.get_how_often_page_has_been_entered(start)).is_equal(2)
	assert_str(loaded._current_story_page.description).not_contains("Never been here.")

func test_random_numbers_go_on_where_they_were() -> void:
	await _choose(_story, 0)
	await await_idle_frame()
	var expected: int = GameRandom.range_int(1, 1000000)
	var loaded: Story = _new_story()
	loaded.restore(_adventure, RUN, SaveGame.read(RUN).story)
	assert_int(GameRandom.range_int(1, 1000000)).is_equal(expected)

func test_no_save_without_a_run() -> void:
	_story.run = ""
	await await_idle_frame()
	await _choose(_story, 0)
	await await_idle_frame()
	assert_bool(FileAccess.file_exists(SaveGame.get_path_of(RUN))).is_false()

func _new_story() -> Story:
	var story: Story = auto_free(load(STORY).instantiate())
	story._reveal_delay = 0.01
	add_child(story)
	return story

func _choose(story: Story, index: int) -> void:
	var page: StoryPage = story._current_story_page
	page.choices[index].chose()
	var waited: int = 0
	while story._current_story_page == page and waited < 5000:
		await await_millis(20)
		waited += 20

static func _location(title: String) -> AdventureLocation:
	var location: AdventureLocation = AdventureLocation.new()
	location.title = title
	location.description = title + "."
	return location
