@tool
class_name Story
extends VBoxContainer

@export var current_page: StoryPage : set = _set_current_page

@export_group("Configuration")
@export var _title: RichTextLabel
@export var _sub_title: RichTextLabel
@export var _story_pages: Container
@export var _story_page_entry: PackedScene

var _page_stack: Array[StoryPage] = [ ]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.location_changed.connect(_on_location_changed)

func _enter_page(story_page: StoryPage = current_page) -> void:
	var story_page_entry: StoryPageEntry = _story_page_entry.instantiate()
	story_page_entry.story_page = story_page
	story_page_entry.page_entered.connect(_set_current_page)
	_story_pages.add_child(story_page_entry)
	_story_pages.move_child(story_page_entry, 0)
	if _story_pages.get_child_count() > 1: story_page_entry.add_sibling(HSeparator.new())

func _set_current_page(new_current_page: StoryPage) -> void:
	if new_current_page != null:
		if current_page != new_current_page:
			_page_stack.push_back(current_page)
			current_page = new_current_page
		else:
			print("Already on page: <%s>!" % current_page)
			return
	else :
		current_page = _page_stack.pop_back()
	_enter_page()

func _on_location_changed(new_location: StoryLocation) -> void:
	_title.text = "[center]%s[/center]" % "Title"
	_sub_title.text = "[center]%s - %s[/center]" % ["Rocky Island", new_location.name]
