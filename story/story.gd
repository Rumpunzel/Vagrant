@tool
class_name Story
extends VBoxContainer

@export var current_page: StoryPage : set = _set_current_page

@export_group("Configuration")
@export var _stage: Stage
@export var _title: TypingLabel
@export var _sub_title: TypingLabel
@export var _pages_container: Container
@export var _story_pages: Container
@export var _page_history: Container
@export var _story_page_entry: PackedScene

var _current_story_page_entry: StoryPageEntry
var _page_stack: Array[StoryPage] = [ ]

func _ready() -> void:
	_enter_page()

func _enter_page(story_page: StoryPage = current_page) -> void:
	_current_story_page_entry = _story_page_entry.instantiate()
	_story_pages.add_child(_current_story_page_entry)
	_story_pages.move_child(_current_story_page_entry, 0)
	_current_story_page_entry.story_page = story_page
	_current_story_page_entry.page_entered.connect(_set_current_page)
	_current_story_page_entry.custom_minimum_size.y = _pages_container.size.y - 8.0
	if story_page is StoryLocation: _enter_location(story_page)
	_stage.story_page = story_page

func _enter_location(story_location: StoryLocation) -> void:
	var previous_story_page := _stage.story_page
	if story_location == previous_story_page: return
	_sub_title.type_text(story_location.to_page_subtitle(), previous_story_page != null)

func _set_current_page(new_current_page: StoryPage) -> void:
	if new_current_page == null: new_current_page = _page_stack.pop_back()
	elif current_page == new_current_page:
		print_debug("Already on page: <%s>!" % current_page)
		return
	if _current_story_page_entry != null:
		_story_pages.remove_child(_current_story_page_entry)
		_page_history.add_child(_current_story_page_entry)
		_page_history.move_child(_current_story_page_entry, 0)
		if _page_history.get_child_count() > 1: _current_story_page_entry.add_sibling(HSeparator.new())
	_page_stack.push_back(current_page)
	current_page = new_current_page
	if is_inside_tree(): _enter_page()
