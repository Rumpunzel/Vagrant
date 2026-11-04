class_name PageRecord
extends RefCounted

## What a page of the story book showed, as data, so the entry can be built again exactly ([method StoryEntry.show_record]): texts as they
## were shown (they depend on the story's state back then), content by [ResourceId], numbers as numbers.

var title: String = ""
var description: String = ""
var background: String = ""
var area_background: String = ""
## { description, icon (ID), color (HTML), chosen }
var choices: Array[Dictionary] = []
## { target, magnitude }
var injuries: Array[Dictionary] = []
## What was picked in the middle of an exchange (in place of the panel it was picked on)
var picks: Array[String] = []
## The last outcome typed below it
var outcome: String = ""
## What the dice showed once rolled ([method BreathDiceSelection.get_record]); empty if nothing was rolled
var dice: Dictionary = {}

static func from_story_page(story_page: StoryPage) -> PageRecord:
	var record: PageRecord = PageRecord.new()
	record.title = story_page.page_title
	record.description = story_page.description
	record.background = ResourceId.of(story_page.background)
	record.area_background = ResourceId.of(story_page.area_background)
	for choice: StoryChoice in story_page.choices:
		record.choices.append({
			description = choice.get_description(),
			icon = ResourceId.of(choice.get_icon()),
			color = choice.get_icon_color().to_html(),
			chosen = false,
		})
	return record

## Marks which of the choices was taken, once the page is left
func take_chosen(story_page: StoryPage) -> void:
	for index: int in mini(choices.size(), story_page.choices.size()): choices[index].chosen = story_page.choices[index].is_chosen()

func get_background() -> Texture2D: return ResourceId.find(background) as Texture2D
func get_area_background() -> Texture2D: return ResourceId.find(area_background) as Texture2D

func get_save() -> Dictionary:
	return {
		title = title, description = description, background = background, area_background = area_background,
		choices = choices.duplicate(true), injuries = injuries.duplicate(true), picks = picks.duplicate(), outcome = outcome,
		dice = dice.duplicate(true),
	}

static func from_save(data: Dictionary) -> PageRecord:
	var record: PageRecord = PageRecord.new()
	record.title = data.get("title", "")
	record.description = data.get("description", "")
	record.background = data.get("background", "")
	record.area_background = data.get("area_background", "")
	var saved_choices: Array = data.get("choices", [])
	var saved_injuries: Array = data.get("injuries", [])
	var saved_picks: Array = data.get("picks", [])
	record.choices.assign(saved_choices)
	record.injuries.assign(saved_injuries)
	record.picks.assign(saved_picks)
	record.outcome = data.get("outcome", "")
	record.dice = data.get("dice", {})
	return record
