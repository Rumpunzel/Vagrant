@tool
class_name AdventureMoveConsequence
extends AdventureConsequence

## Puts an encounter at one location, where it is from then on (first contact narrows where it could be to here)

## By UID; empty: the encounter of the event one is in
@export_file("*.tres") var encounter: String
## By UID; empty: the current location
@export_file("*.tres") var to: String

func resolve(story: Story, _margin: int) -> void:
	var moving: AdventureEncounter = story.get_subject(encounter, null) as AdventureEncounter
	var location: AdventureLocation = Files.load_existing(to) as AdventureLocation if not to.is_empty() else story.get_location()
	var places: Array[AdventureLocation] = [location]
	if moving != null and location != null: story.world.move(moving, places)

func describe() -> String:
	return "%s → %s" % [AdventureStageCondition.name_subject(encounter), "here" if to.is_empty() else AdventureStageCondition.name_subject(to)]
