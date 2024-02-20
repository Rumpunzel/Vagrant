@tool
class_name Story
extends VBoxContainer

@export var first_story_page: StoryPage :
	set(new_first_story_page):
		first_story_page = new_first_story_page
		_append_page(first_story_page)

@export_group("Configuration")
@export var _title: RichTextLabel
@export var _sub_title: RichTextLabel
@export var _scroll_container: ScrollContainer
@export var _story_pages: Container
@export var _story_page_entry: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Events.location_changed.connect(_on_location_changed)

func _append_page(story_page: StoryPage) -> void:
	var story_page_entry: StoryPageEntry = _story_page_entry.instantiate()
	story_page_entry.story_page = story_page
	story_page_entry.new_page_requested.connect(_append_page)
	story_page_entry.hit_dice_selection_added.connect(_scroll_container.ensure_control_visible)
	_story_pages.add_child(story_page_entry)

func _on_location_changed(new_location: StoryLocation) -> void:
	_title.text = "[center]%s[/center]" % "Title"
	_sub_title.text = "[center]%s - %s[/center]" % ["Rocky Island", new_location.name]
