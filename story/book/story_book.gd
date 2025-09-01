class_name StoryBook
extends VBoxContainer

signal page_entered(story_page: StoryPage)

@export_range(0.0, 1.0) var _page_turn_delay: float = 0.0
@export_range(0.0, 5.0) var _dice_page_turn_delay: float = 2.0

@export_group("Configuration")
@export var _page_turn_timer: Timer
@export var _title: TypingLabel
@export var _sub_title: TypingLabel
@export var _story_pages: Container
@export var _story_page_entry: PackedScene

var _story: Story
var _characters: Characters

var _current_story_page_entry: StoryPageEntry

func setup(story: Story, characters: Characters) -> void:
	_story = story
	_characters = characters
	_story.page_entered.connect(_on_page_entered)

func _exit_tree() -> void:
	_story.page_entered.disconnect(_on_page_entered)

func _flip_page(first_page: bool = false) -> void:
	if not first_page:
		var separator: HSeparator = HSeparator.new()
		_story_pages.add_child(separator)
		_story_pages.move_child(separator, 0)
	_story_pages.add_child(_current_story_page_entry)
	_story_pages.move_child(_current_story_page_entry, 0)
	var sub_title: String = _current_story_page_entry.story_page.get_page_title(_story)
	if not sub_title.is_empty(): _sub_title.type_text(sub_title)
	_current_story_page_entry.enter_page()
	page_entered.emit(_current_story_page_entry.story_page)

func _on_page_entered(story_page: StoryPage) -> void:
	var previous_page: StoryPageEntry = _current_story_page_entry
	_current_story_page_entry = _story_page_entry.instantiate()
	_current_story_page_entry.setup_page(_story, _characters, story_page)
	if not previous_page: _flip_page(true)
	else:
		var delay: float = _dice_page_turn_delay if previous_page.is_dice_page() else _page_turn_delay
		if delay > 0: _page_turn_timer.start(delay)
		else: _on_page_turn_delay_timeout()

func _on_page_turn_delay_timeout() -> void:
	_flip_page()
