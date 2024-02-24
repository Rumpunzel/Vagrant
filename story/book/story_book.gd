class_name StoryBook
extends VBoxContainer

@export_group("Configuration")
@export var _stage: Stage
@export var _title: TypingLabel
@export var _sub_title: TypingLabel
@export var _story_pages: Container
@export var _page_history: Container
@export var _story_page_entry: PackedScene

var _current_story_page_entry: StoryPageEntry

func _enter_tree() -> void:
	Story.page_entered.connect(_on_page_entered)

func _exit_tree() -> void:
	Story.page_entered.disconnect(_on_page_entered)

func _on_page_entered(story_page: StoryPage) -> void:
	if _current_story_page_entry != null:
		_story_pages.remove_child(_current_story_page_entry)
		_page_history.add_child(_current_story_page_entry)
		_page_history.move_child(_current_story_page_entry, 0)
		if _page_history.get_child_count() > 1: _current_story_page_entry.add_sibling(HSeparator.new())
	_current_story_page_entry = _story_page_entry.instantiate()
	_story_pages.add_child(_current_story_page_entry)
	_story_pages.move_child(_current_story_page_entry, 0)
	_current_story_page_entry.story_page = story_page
	var previous_story_page := _stage.story_page
	if story_page == previous_story_page: return
	var sub_title := story_page.get_page_title()
	if not sub_title.is_empty(): _sub_title.type_text(sub_title, previous_story_page != null)
	_stage.story_page = story_page
