extends GdUnitTestSuite

## The story book keeps the last pages when a new one is entered, builds older ones again from what they showed when scrolling up, and a
## loaded run shows its pages before the one it goes on from.

const STORY: String = "uid://db6oui711vqep"  # story.tscn
const ADVENTURE_PATH: String = "user://story_book_history_test_adventure.tres"

var _story: Story
var _adventure: Adventure

func before_test() -> void:
	var start: AdventureLocation = _location("Start")
	var next: AdventureLocation = _location("Next")
	start.first_description = "Never been here."
	start.decisions = [_decision("Go on", next)] as Array[AdventureDecision]
	next.decisions = [_decision("Go back", start), _decision("Stay", null)] as Array[AdventureDecision]
	var adventure: Adventure = Adventure.new()
	adventure.title = "History"
	adventure.starting_page = start
	# A file, so a save can name its pages
	ResourceSaver.save(adventure, ADVENTURE_PATH)
	_adventure = ResourceLoader.load(ADVENTURE_PATH, "", ResourceLoader.CACHE_MODE_REPLACE)
	_adventure.protagonist = TestCharacters.adventurer()
	_story = _new_story()
	_story.start_adventure(_adventure, TestCharacters.adventurer())

func after_test() -> void:
	await await_millis(500)
	DirAccess.remove_absolute(ADVENTURE_PATH)

func test_keeps_the_last_pages() -> void:
	for _index: int in 7: await _choose(_story, 0)
	var book: StoryBook = _story._story_book
	assert_int(book._pages.get_elements().size()).is_equal(StoryBook.KEPT_PAGES)
	assert_int(book._records.size()).is_equal(7)

func test_scrolling_up_builds_older_pages_as_they_were() -> void:
	for _index: int in 7: await _choose(_story, 0)
	var book: StoryBook = _story._story_book
	book.show_older_pages()
	var entries: Array[Control] = book._pages.get_elements()
	assert_int(entries.size()).is_equal(8)
	var first: StoryEntry = entries[0]
	assert_str(first._title.text).is_equal("Start")
	assert_str(first._description.text).contains("Never been here.")
	var buttons: Array[Control] = first._choices.get_elements()
	assert_str((buttons[0] as DialogButton).text).is_equal("Go on")
	assert_bool((buttons[0] as DialogButton).disabled).is_false()
	assert_int(first.state).is_equal(PageEntry.State.PAST)
	# Nothing older left
	book.show_older_pages()
	assert_int(book._pages.get_elements().size()).is_equal(8)
	# A new page trims the book again
	await _choose(_story, 0)
	assert_int(book._pages.get_elements().size()).is_equal(StoryBook.KEPT_PAGES)

func test_a_loaded_run_shows_its_pages() -> void:
	for _index: int in 3: await _choose(_story, 0)
	var save: Dictionary = _through_json(_story.get_save())
	var loaded: Story = _new_story()
	loaded.restore(_adventure, "", save)
	var entries: Array[Control] = loaded._story_book._pages.get_elements()
	assert_int(entries.size()).is_equal(4)
	assert_str((entries[0] as StoryEntry)._title.text).is_equal("Start")
	assert_str((entries[1] as StoryEntry)._title.text).is_equal("Next")

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

static func _decision(description: String, to: AdventurePage) -> AdventureDecision:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.description = description
	decision.transition = to
	return decision

static func _through_json(data: Variant) -> Variant: return JSON.parse_string(JSON.stringify(data))
