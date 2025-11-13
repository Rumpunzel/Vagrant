class_name StoryBook
extends PanelContainer

signal page_entered(page_entry: PageEntry)

@export_range(0.0, 1.0, 0.1, "suffix:seconds") var _page_turn_delay: float = 0.0
@export_range(0.0, 5.0, 0.1, "suffix:seconds") var _dice_page_turn_delay: float = 3.0
@export_range(0.0, 1.0, 0.05, "suffix:percentage") var _initial_page_size: float = 0.5

@export_group("Configuration")
@export var _page_turn_timer: Timer
@export var _page_content_slider: Slider
@export var _pages: FlexContainer

var _adventure_tome: AdventureTome
var _story: Story
var _characters: Characters

var _current_page_entry: PageEntry

func _ready() -> void:
	await get_tree().process_frame
	_page_content_slider.value = _page_content_slider.max_value * _initial_page_size

func setup(adventure_tome: AdventureTome, story: Story, characters: Characters) -> void:
	_adventure_tome = adventure_tome
	_story = story
	_characters = characters
	_story.page_entered.connect(_on_page_entered)

func _exit_tree() -> void:
	_story.page_entered.disconnect(_on_page_entered)

func _flip_page() -> void:
	assert(_current_page_entry)
	_current_page_entry.custom_minimum_size.y = _page_content_slider.value
	_pages.add(_current_page_entry)
	_current_page_entry.enter_page()
	_current_page_entry.resized.connect(_on_current_page_entry_resized)
	page_entered.emit(_current_page_entry)

func _on_page_entered(story_page: StoryPage) -> void:
	assert(story_page)
	var previous_page: StoryEntry = _current_page_entry
	_current_page_entry = story_page.create()
	_current_page_entry.setup_page(_story, _characters, story_page)
	if not previous_page: _flip_page()
	else:
		var delay: float = _dice_page_turn_delay if previous_page.is_dice_page() else _page_turn_delay
		if delay > 0:
			_page_turn_timer.start(delay)
			await _page_turn_timer.timeout
			previous_page.resized.disconnect(_on_current_page_entry_resized)
			previous_page.custom_minimum_size.y = 0
		else:
			previous_page.resized.disconnect(_on_current_page_entry_resized)
			previous_page.custom_minimum_size.y = 0
			_flip_page()

func _on_page_turn_delay_timeout() -> void:
	_flip_page()

func _on_current_page_entry_resized() -> void:
	assert(_current_page_entry)
	if _current_page_entry.size.y < _page_content_slider.value: return
	await get_tree().process_frame
	_page_content_slider.set_value_no_signal(_current_page_entry.size.y)

func _on_page_content_slider_value_changed(value: float) -> void:
	if not _current_page_entry: return
	var entry_min_height: float = _current_page_entry.get_minimum_size().y
	if value < entry_min_height:
		_page_content_slider.set_value_no_signal(entry_min_height)
		return
	_current_page_entry.custom_minimum_size.y = value

func _on_resized() -> void:
	_page_content_slider.max_value = size.y - 32.0
