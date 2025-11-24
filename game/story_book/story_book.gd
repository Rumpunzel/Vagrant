class_name StoryBook
extends PanelContainer

signal page_entered(page_entry: PageEntry)

@export_range(0.0, 1.0, 0.05, "suffix:percentage") var _initial_page_size: float = 0.5

@export_group("Configuration")
@export var _page_content_slider: Slider
@export var _pages: FlexContainer

var _current_page_entry: PageEntry

func _ready() -> void:
	await get_tree().process_frame
	_on_resized()
	_page_content_slider.value = _page_content_slider.max_value * _initial_page_size

func enter_story_page(story_page: StoryPage) -> void:
	assert(story_page)
	if _current_page_entry:
		_current_page_entry.resized.disconnect(_on_current_page_entry_resized)
		_current_page_entry.custom_minimum_size.y = 0
	_current_page_entry = story_page.create_story_entry()
	_flip_page()

func display_dice_result(dice_result: DiceRequestResult) -> void:
	assert(_current_page_entry)
	_current_page_entry.display_dice_result(dice_result)

func _flip_page() -> void:
	assert(_current_page_entry)
	_current_page_entry.custom_minimum_size.y = _page_content_slider.value
	_pages.add(_current_page_entry)
	_current_page_entry.enter_page()
	_current_page_entry.resized.connect(_on_current_page_entry_resized)
	page_entered.emit(_current_page_entry)

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
