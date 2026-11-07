@tool
class_name AdventureEncounter
extends AdventureEventScenario

## Someone or something in the world (an NPC; later monsters and items). Its events show where it is, near it or anywhere
## ([member AdventureEvent.where]); its stage tracks tell where its story stands. Listed in [member Adventure.encounters].

const ENCOUNTER_UNUSED: Array[StringName] = [&"where", &"only_at", &"nearby_reach", &"nearby_stays_in_area"]

@export var profile: ActorProfile
## What its monster has besides its gear, taken by looting it ([AdventureLootDecision]): item -> how many
@export var loot: Dictionary[ItemProfile, int] = {}
@export var tracks: Array[AdventureStageTrack]
## Where it could be (UIDs), until a move ([AdventureMoveConsequence]) puts it somewhere; first contact usually narrows it to one
@export_file("*.tres") var places: Array[String]

func get_places() -> Array[AdventureLocation]:
	var locations: Array[AdventureLocation] = [ ]
	for place: String in places:
		var location: AdventureLocation = Files.load_existing(place) as AdventureLocation
		if location != null and not locations.has(location): locations.append(location)
	return locations

func resolve_events(story: Story, location: AdventureLocation, _encounter: AdventureEncounter) -> Array[AdventureEvent]:
	return super(story, location, self)

func could_show_at(story: Story, location: AdventureLocation, _encounter: AdventureEncounter) -> bool:
	return super(story, location, self)

func _validate_property(property: Dictionary) -> void:
	super(property)
	if ENCOUNTER_UNUSED.has(property.name): property.usage = PROPERTY_USAGE_NO_EDITOR
