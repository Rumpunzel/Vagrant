@tool
class_name AdventurePlaceCondition
extends AdventureCondition

## True while an encounter is (or could be) at a location, or somewhere in an area

## By UID; empty: the event's own encounter
@export_file("*.tres") var encounter: String
## A location or an area, by UID; empty: the current location
@export_file("*.tres") var at: String

func is_true(story: Story, page: AdventurePage) -> bool:
	var target: AdventureEncounter = story.get_subject(encounter, page) as AdventureEncounter
	if target == null: return false
	var place: Resource = Files.load_existing(at) if not at.is_empty() else story.get_location()
	for location: AdventureLocation in story.world.get_places(target):
		if location == place or place is AdventureArea and location.area == place: return true
	return false

func describe() -> String:
	var who: String = "It" if encounter.is_empty() else AdventureStageCondition.name_subject(encounter)
	return "%s is %s" % [who, "here" if at.is_empty() else "at " + AdventureStageCondition.name_subject(at)]
