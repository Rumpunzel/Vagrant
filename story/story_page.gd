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

func _init(
	protagonist_getter: Callable,
	from_adventure_page: AdventurePage,
	from_page_title: String,
	from_description: String,
	from_background: Texture2D,
	from_ambience: AudioStream,
	from_choices: Array[AdventureDecision],
	from_events: Array[AdventurePage],
) -> void:
	adventure_page = from_adventure_page
	page_title = from_page_title
	description = from_description
	background = from_background
	area_background = adventure_page.get_area_background()
	ambience = from_ambience
	if from_choices.is_empty(): from_choices.append(AdventureDecision.get_continue())
	choices.assign(from_choices.map(StoryChoice.from_story_decision.bind(protagonist_getter)))
	events = from_events

func create_story_entry() -> StoryEntry:
	var story_entry_scene: PackedScene = load("uid://cy2ymcfk2tejn")
	var story_entry: StoryEntry = story_entry_scene.instantiate()
	story_entry.setup_page(self)
	return story_entry

func get_chosen_choice() -> StoryChoice:
	for choice: StoryChoice in choices: if choice.is_chosen(): return choice
	return null
