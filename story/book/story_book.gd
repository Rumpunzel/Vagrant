class_name StoryBook
extends PanelContainer

signal page_entered(page_entry: PageEntry)
signal page_size_changed

@export_range(0.0, 1.0) var _page_turn_delay: float = 0.0
@export_range(0.0, 5.0) var _dice_page_turn_delay: float = 3.0

@export_group("Configuration")
@export var _page_turn_timer: Timer
@export var _page_content_slider: Slider
@export var _pages: FlexContainer

var _adventure_tome: AdventureTome
var _story: Story
var _characters: Characters

var _current_page_entry: PageEntry

func _ready() -> void:
	var dummy_control: Control = Control.new()
	dummy_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dummy_control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_pages.add(dummy_control)

func setup(adventure_tome: AdventureTome, story: Story, characters: Characters) -> void:
	_adventure_tome = adventure_tome
	_story = story
	_characters = characters
	_story.page_entered.connect(_on_page_entered)

func _exit_tree() -> void:
	_story.page_entered.disconnect(_on_page_entered)

func _flip_page() -> void:
	assert(_current_page_entry)
	_current_page_entry.resized.connect(_on_current_page_entry_resized)
	_current_page_entry.custom_minimum_size.y = _page_content_slider.value
	_pages.add(_current_page_entry)
	_current_page_entry.enter_page()
	page_entered.emit(_current_page_entry)

func _on_page_entered(story_page: StoryPage) -> void:
	assert(story_page)
	var previous_page: StoryEntry = _current_page_entry
	_current_page_entry = story_page.create()
	_current_page_entry.setup_page(_story, _characters, story_page)
	if not previous_page: _flip_page()
	else:
		previous_page.resized.disconnect(_on_current_page_entry_resized)
		previous_page.custom_minimum_size.y = 0
		var delay: float = _dice_page_turn_delay if previous_page.is_dice_page() else _page_turn_delay
		if delay > 0: _page_turn_timer.start(delay)
		else: _flip_page()

func _on_page_turn_delay_timeout() -> void:
	_flip_page()

func _on_current_page_entry_resized() -> void:
	assert(_current_page_entry)
	_page_content_slider.set_value_no_signal(_current_page_entry.size.y)
	page_size_changed.emit()

func _on_page_content_slider_value_changed(value: float) -> void:
	if not _current_page_entry: return
	var entry_min_height: float = _current_page_entry.get_minimum_size().y
	if value < entry_min_height:
		_page_content_slider.set_value_no_signal(entry_min_height)
		return
	_current_page_entry.custom_minimum_size.y = value
	page_size_changed.emit()

func _on_resized() -> void:
	_page_content_slider.max_value = size.y - 32.0
