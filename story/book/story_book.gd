class_name StoryBook
extends VBoxContainer

signal page_entered(story_page: StoryPage)

@export_group("Configuration")
@export var _title: TypingLabel
@export var _sub_title: TypingLabel
@export var _story_pages: Container
@export var _page_history: Container
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

func _on_page_entered(story_page: StoryPage) -> void:
	if _current_story_page_entry != null:
		_story_pages.remove_child(_current_story_page_entry)
		_page_history.add_child(_current_story_page_entry)
		_current_story_page_entry.size_flags_vertical = Control.SIZE_FILL
		_page_history.move_child(_current_story_page_entry, 0)
		if _page_history.get_child_count() > 1: _current_story_page_entry.add_sibling(HSeparator.new())
	_current_story_page_entry = _story_page_entry.instantiate()
	_story_pages.add_child(_current_story_page_entry)
	_story_pages.move_child(_current_story_page_entry, 0)
	_current_story_page_entry.enter_page(_story, _characters, story_page)
	var sub_title: String = story_page.get_page_title(_story)
	if not sub_title.is_empty(): _sub_title.type_text(sub_title)
	page_entered.emit(story_page)
