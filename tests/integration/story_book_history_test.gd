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

## A past page still takes the mouse (its tooltips work, hovering shows it fully), but none of its controls a click, focus or key
func test_past_pages_are_inert_but_hoverable() -> void:
	await _choose(_story, 0)
	var past: StoryEntry = _story._story_book._pages.get_elements()[0]
	assert_int(past.state).is_equal(PageEntry.State.PAST)
	assert_bool(past.is_processing()).is_true()
	for node: Node in past.find_children("*", "Control", true, false):
		var control: Control = node
		assert_int(control.mouse_behavior_recursive).is_not_equal(Control.MOUSE_BEHAVIOR_DISABLED)
		assert_int(control.focus_mode).is_equal(Control.FOCUS_NONE)
		if control is BaseButton:
			assert_int((control as BaseButton).button_mask).is_equal(0)
			assert_object((control as BaseButton).shortcut).is_null()
	var present: StoryEntry = _story._story_book._current_page_entry
	assert_bool(present.is_processing()).is_false()

func test_dice_are_built_again_as_they_were() -> void:
	var decision: AdventureSaveDecision = AdventureSaveDecision.new()
	decision.description = "Jump"
	decision.attribute = Rules.AGILITY
	decision.difficulty = 1
	var end_page: AdventurePage = AdventurePage.new()
	end_page.title = "End"
	decision.transition = end_page
	decision.failure_transition = end_page
	var page: AdventurePage = AdventurePage.new()
	page.title = "Ledge"
	page.decisions = [decision] as Array[AdventureDecision]
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = page
	var story: Story = _new_story()
	story.start_adventure(adventure, TestCharacters.adventurer())
	var choice: StoryChoice = story._current_story_page.choices[0]
	choice.chose()
	await await_millis(50)
	var shown: StoryPage = story._current_story_page
	choice.roll()
	var waited: int = 0
	while story._current_story_page == shown and waited < 5000:
		await await_millis(20)
		waited += 20
	var book: StoryBook = story._story_book
	var record: PageRecord = book._records[0]
	assert_dict(record.dice).is_not_empty()
	var live: BreathDiceSelection = (book._pages.get_elements()[0] as StoryEntry)._breath_dice_selection
	var rebuilt_entry: StoryEntry = auto_free(StoryBook.STORY_ENTRY.instantiate())
	add_child(rebuilt_entry)
	var saved_record: Dictionary = _through_json(record.get_save())
	rebuilt_entry.show_record(PageRecord.from_save(saved_record))
	var rebuilt: BreathDiceSelection = rebuilt_entry._breath_dice_selection
	assert_str(rebuilt._dice_log_save_result_entry.get_text()).is_equal(live._dice_log_save_result_entry.get_text())
	assert_str(rebuilt._description.text).is_equal(live._description.text)
	assert_array(_through_json(rebuilt._breath_dice_selection_buttons.get_record())).is_equal(_through_json(record.dice.dice))
	assert_str(rebuilt_entry._title.text).is_equal("Ledge")
	# Open, as on the live page
	await await_millis(100)
	assert_int(rebuilt_entry._breath_dice_collapsible_container.get_opened_state()).is_equal(CollapsibleContainer.OpenedStates.OPENED)

func _new_story() -> Story:
	var scene: PackedScene = load(STORY)
	var story: Story = auto_free(scene.instantiate())
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
