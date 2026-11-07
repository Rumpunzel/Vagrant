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
var events: Array[AdventureEvent]
## Set on fight exchange pages, which are not adventure pages of their own
var fight: Fight
## Made by the story between authored pages, like looting ([method is_in_between])
var in_between: bool = false
## Taken right away instead of showing the page, e.g. a fight lost on arrival
var forced_choice: StoryChoice
## The party can neither catch its breath nor make camp here ([method AdventurePage.forbids_rest])
var forbids_rest: bool = false

func _init(
	from_adventure_page: AdventurePage,
	from_page_title: String,
	from_description: String,
	from_background: Texture2D,
	from_ambience: AudioStream,
	from_choices: Array[StoryChoice],
	from_events: Array[AdventureEvent],
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
## A page the story makes between authored ones (a fight's exchanges, looting): not kept in the page stack, not counted as entered, not saved on
func is_in_between() -> bool: return is_fight_exchange() or in_between
## The first page of a fight offers it, every following exchange belongs to it
func is_fighting() -> bool: return is_fight_exchange() or choices.any(func(choice: StoryChoice) -> bool: return choice is StoryFightDecision)

func create_story_entry() -> StoryEntry:
	var story_entry_scene: PackedScene = load("uid://cy2ymcfk2tejn")
	var story_entry: StoryEntry = story_entry_scene.instantiate()
	story_entry.setup_page(self)
	return story_entry

func get_chosen_choice() -> StoryChoice:
	for choice: StoryChoice in choices: if choice.is_chosen(): return choice
	return null
