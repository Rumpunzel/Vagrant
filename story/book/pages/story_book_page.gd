@tool
class_name StoryBookPage
extends RefCounted

var story_page: StoryPage
var page_title: String
var description: String
var background: Texture2D
var area_background: Texture2D
var ambience: AudioStream
var choices: Array[StoryBookChoice]
var events: Array[StoryPage]

func _init(
	protagonist: Character,
	from_story_page: StoryPage,
	from_page_title: String,
	from_description: String,
	from_background: Texture2D,
	from_ambience: AudioStream,
	from_choices: Array[StoryDecision],
	from_events: Array[StoryPage],
) -> void:
	story_page = from_story_page
	page_title = from_page_title
	description = from_description
	background = from_background
	area_background = story_page.get_area_background()
	ambience = from_ambience
	if from_choices.is_empty(): from_choices.append(StoryDecision.get_continue())
	choices.assign(from_choices.map(StoryBookChoice.from_story_decision.bind(protagonist)))
	events = from_events

func create_story_entry() -> StoryEntry:
	var story_entry_scene: PackedScene = load("uid://cy2ymcfk2tejn")
	var story_entry: StoryEntry = story_entry_scene.instantiate()
	return story_entry

func get_chosen_choice() -> StoryBookChoice:
	for choice: StoryBookChoice in choices: if choice.is_chosen(): return choice
	return null
