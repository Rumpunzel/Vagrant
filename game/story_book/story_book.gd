class_name StoryBook
extends PanelContainer

## The pages of the story, newest at the bottom. Keeps [constant KEPT_PAGES] entries when a new page is entered; what every page showed is
## kept as a [PageRecord], so scrolling to the top builds the older ones again ([method show_older_pages]), and a loaded run shows them too.

signal page_entered(page_entry: PageEntry)

## Entries left in the book when a new page is entered (the new one among them); scrolling up adds this many older ones each time
const KEPT_PAGES: int = 5
const STORY_ENTRY: PackedScene = preload("uid://cy2ymcfk2tejn")  # story_entry.tscn

@export_range(0.0, 1.0, 0.05, "suffix:percentage") var _initial_page_size: float = 0.5

@export_group("Configuration")
@export var _page_content_slider: Slider
@export var _pages: FlexContainer
@export var _scroll_container: AutoScrollContainer

var _current_page_entry: PageEntry
## What each page before the current one showed, oldest first
var _records: Array[PageRecord] = []
## What the current page shows so far; recorded once it is left
var _current_record: PageRecord
## Index in [member _records] of the oldest page in the book
var _first_shown: int = 0

func _ready() -> void:
	_scroll_container.get_v_scroll_bar().value_changed.connect(_on_scrolled)
	_scroll_container.gui_input.connect(_on_scroll_container_gui_input)
	await get_tree().process_frame
	_on_resized()
	_page_content_slider.value = _page_content_slider.max_value * _initial_page_size

func enter_story_page(story_page: StoryPage) -> void:
	assert(story_page)
	if _current_page_entry:
		_current_page_entry.resized.disconnect(_on_current_page_entry_resized)
		_current_page_entry.custom_minimum_size.y = 0
		_current_page_entry.state = PageEntry.State.PAST
		_current_record.take_chosen(_current_page_entry.get_story_page())
		_current_record.dice = (_current_page_entry as StoryEntry).get_dice_record()
		_records.append(_current_record)
	_current_page_entry = story_page.create_story_entry()
	_current_record = PageRecord.from_story_page(story_page)
	_flip_page()
	_trim()

func display_dice_result(dice_result: DiceRequestResult) -> void:
	assert(_current_page_entry)
	_current_page_entry.display_dice_result(dice_result)

func display_dice_evaluation(dice_result: DiceRequestResult) -> void:
	assert(_current_page_entry is StoryEntry)
	(_current_page_entry as StoryEntry).display_dice_evaluation(dice_result)

func show_injury(target_name: String, magnitude: int) -> void:
	assert(_current_page_entry is StoryEntry)
	(_current_page_entry as StoryEntry).show_injury(target_name, magnitude)
	_current_record.injuries.append({target = target_name, magnitude = magnitude})

func show_panel(panel: Control) -> void:
	assert(_current_page_entry is StoryEntry)
	(_current_page_entry as StoryEntry).show_panel(panel)

## What was picked on a panel ([method show_panel]), shown and kept in its place
func show_pick(pick: String) -> void:
	assert(_current_page_entry is StoryEntry)
	(_current_page_entry as StoryEntry).show_pick(pick)
	_current_record.picks.append(pick)

## Starts typing the text below the current page's roll and injuries
func show_outcome(outcome: String) -> void:
	assert(_current_page_entry is StoryEntry)
	(_current_page_entry as StoryEntry).show_outcome(outcome)
	if not outcome.is_empty(): _current_record.outcome = outcome

func is_outcome_typed() -> bool: return (_current_page_entry as StoryEntry).is_outcome_typed()
## Emitted once the current page's outcome is fully typed out (or skipped)
func get_outcome_typed() -> Signal: return (_current_page_entry as StoryEntry).get_outcome_typed()

## Builds up to [constant KEPT_PAGES] pages before the oldest one in the book again, above it, keeping what is in view where it is
func show_older_pages() -> void:
	if _first_shown == 0: return
	var from: int = maxi(_first_shown - KEPT_PAGES, 0)
	var scroll_bar: VScrollBar = _scroll_container.get_v_scroll_bar()
	scroll_bar.changed.connect(_keep_view.bind(scroll_bar.max_value), CONNECT_ONE_SHOT)
	for index: int in range(_first_shown - 1, from - 1, -1):
		var entry: StoryEntry = STORY_ENTRY.instantiate()
		_pages.add(entry)
		entry.get_parent().move_child(entry, 0)
		entry.show_record(_records[index])
	_first_shown = from

## What the pages before the current one showed ([PageRecord]), for a save
func get_save() -> Array[Dictionary]:
	var saved: Array[Dictionary] = []
	for record: PageRecord in _records: saved.append(record.get_save())
	return saved

## A loaded run's pages before the one it goes on from: the last ones are shown, the rest when scrolling up
func restore(saved: Array) -> void:
	_records.clear()
	for data: Dictionary in saved: _records.append(PageRecord.from_save(data))
	_first_shown = _records.size()
	show_older_pages()

func _flip_page() -> void:
	assert(_current_page_entry)
	_current_page_entry.custom_minimum_size.y = _page_content_slider.value
	_pages.add(_current_page_entry)
	_current_page_entry.enter_page()
	_current_page_entry.resized.connect(_on_current_page_entry_resized)
	page_entered.emit(_current_page_entry)

## Down to [constant KEPT_PAGES] entries, the oldest go; their records stay
func _trim() -> void:
	var entries: Array[Control] = _pages.get_elements()
	if entries.size() <= KEPT_PAGES: return
	for entry: Control in entries.slice(0, entries.size() - KEPT_PAGES):
		_pages.remove(entry)
		entry.queue_free()
	_first_shown = _records.size() - (KEPT_PAGES - 1)
	_scroll_container.reset_scroll_tracking()

func _keep_view(max_before: float) -> void:
	_scroll_container.shift_vertical(_scroll_container.get_v_scroll_bar().max_value - max_before)

func _on_scrolled(value: float) -> void:
	if value <= 0.0: show_older_pages()

## Scrolling up at the top, where the scroll bar can't go further (also when everything fits)
func _on_scroll_container_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton: return
	var button: InputEventMouseButton = event
	if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP and _scroll_container.scroll_vertical <= 0: show_older_pages()

func _on_current_page_entry_resized() -> void:
	assert(_current_page_entry)
	await get_tree().process_frame
	var current_size: float = _current_page_entry.size.y
	if current_size < _page_content_slider.value: return
	_page_content_slider.value = current_size

func _on_page_content_slider_value_changed(value: float) -> void:
	if not _current_page_entry: return
	var entry_min_height: float = _current_page_entry.get_minimum_size().y
	if value < entry_min_height:
		_page_content_slider.set_value_no_signal(entry_min_height)
		return
	_current_page_entry.custom_minimum_size.y = value

func _on_resized() -> void:
	_page_content_slider.max_value = size.y - 32.0
