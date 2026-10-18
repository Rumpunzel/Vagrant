@tool
class_name StoryPage
extends RefCounted

var adventure_page: AdventurePage
var page_title: String
var description: String
var background: Texture2D
var area_background: Texture2D
var ambience: AudioStream
var choices: Array[StoryChoice]
var events: Array[AdventurePage]
## Set on fight exchange pages, which are not adventure pages of their own
var fight: Fight
## Taken right away instead of showing the page, e.g. a fight lost on arrival
var forced_choice: StoryChoice

func _init(
	from_adventure_page: AdventurePage,
	from_page_title: String,
	from_description: String,
	from_background: Texture2D,
	from_ambience: AudioStream,
	from_choices: Array[StoryChoice],
	from_events: Array[AdventurePage],
) -> void:
	adventure_page = from_adventure_page
	page_title = from_page_title
	description = from_description
	background = from_background
	area_background = adventure_page.get_area_background()
	ambience = from_ambience
	assert(not from_choices.is_empty())
	choices = from_choices
	events = from_events

func is_fight_exchange() -> bool: return fight != null

func create_story_entry() -> StoryEntry:
	var story_entry_scene: PackedScene = load("uid://cy2ymcfk2tejn")
	var story_entry: StoryEntry = story_entry_scene.instantiate()
	story_entry.setup_page(self)
	return story_entry

func get_chosen_choice() -> StoryChoice:
	for choice: StoryChoice in choices: if choice.is_chosen(): return choice
	return null
