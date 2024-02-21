@tool
class_name Story
extends VBoxContainer

@export var current_page: StoryPage : set = _set_current_page

@export_group("Configuration")
@export var _title: RichTextLabel
@export var _sub_title: RichTextLabel
@export var _story_pages: Container
@export var _stage: Stage
@export var _story_page_entry: PackedScene

var _page_stack: Array[StoryPage] = [ ]

func _enter_page(story_page: StoryPage = current_page) -> void:
	if story_page is StoryLocation: _enter_location(story_page)
	var story_page_entry: StoryPageEntry = _story_page_entry.instantiate()
	story_page_entry.story_page = story_page
	story_page_entry.page_entered.connect(_set_current_page)
	_story_pages.add_child(story_page_entry)
	_story_pages.move_child(story_page_entry, 0)
	if _story_pages.get_child_count() > 1: story_page_entry.add_sibling(HSeparator.new())

func _enter_location(story_location: StoryLocation) -> void:
	_sub_title.text = story_location.to_page_subtitle()
	_stage.location = story_location

func _set_current_page(new_current_page: StoryPage) -> void:
	if new_current_page == null: current_page = _page_stack.pop_back()
	else:
		if current_page != new_current_page:
			_page_stack.push_back(current_page)
			current_page = new_current_page
		else:
			print("Already on page: <%s>!" % current_page)
			return
	_enter_page()

func _on_location_changed(new_location: StoryLocation) -> void:
	_title.text = "[center]%s[/center]" % "Title"
	_sub_title.text = "[center]%s - %s[/center]" % ["Rocky Island", new_location.name]
