@tool
class_name AdventureEvent
extends AdventurePage

## Shown on a location while its conditions are met: as one of the location's own events, or an encounter's, by [member where];
## [member exclusivity] decides what else stays visible

enum Exclusivity {
	NONE = 0,
	EXCLUDE_BASE = 1,
	EXCLUDE_BELOW = 2,
	EXCLUDE_ABOVE = 4,
}

enum Where {
	## Where its encounter is (or could be)
	ENCOUNTER,
	## Near where its encounter is (or could be), within [member nearby_reach], not there itself
	NEAR,
	ANYWHERE,
}

## How far "near" is looked for, also for a reach of the whole area
const MAX_NEARBY_REACH: int = 8

@export var conditions: Array[AdventureCondition]
@export_flags("Hide Base:1", "Hide Below:2", "Hide Above:4", "Hide All:7")
var exclusivity: int = 0
## Each host gets its own of what this event spawns (monsters); otherwise all hosts share them
@export var generic: bool = false
## For an encounter's events; a location's own events show there
@export var where: Where = Where.ENCOUNTER
## Only on these locations, or locations in these areas (UIDs); none: no such limit
@export_file("*.tres") var only_at: Array[String]
## Near: how many links from where its encounter is; 0: anywhere in the same area
@export_range(0, MAX_NEARBY_REACH) var nearby_reach: int = 1
## Near: only on locations in the same area as where its encounter is
@export var nearby_stays_in_area: bool = false

func are_all_prerequisites_fullfilled(story: Story) -> bool:
	for condition: AdventureCondition in conditions:
		if not condition.is_true(story, self): return false
	return true

## What [param location] shows for this event, once its prerequisites are met: the event itself if it can show there (a scenario: the ones
## it picks); [param encounter]: the encounter it belongs to, none for a location's own events
func resolve_events(story: Story, location: AdventureLocation, encounter: AdventureEncounter) -> Array[AdventureEvent]:
	var shown: Array[AdventureEvent] = [ ]
	if encounter == null or can_show_at(story, location, encounter): shown.append(self)
	return shown

func can_show_at(story: Story, location: AdventureLocation, encounter: AdventureEncounter) -> bool:
	if not only_at.is_empty() and not is_allowed_at(location): return false
	match where:
		Where.ENCOUNTER: return story.world.get_places(encounter).has(location)
		Where.NEAR: return story.world.is_near(encounter, location, nearby_reach, nearby_stays_in_area)
	return true

## Whether [member only_at] lets it show at [param location]
func is_allowed_at(location: AdventureLocation) -> bool:
	for path: String in only_at:
		var allowed: Resource = Files.load_existing(path)
		if allowed != null and (allowed == location or allowed == location.area): return true
	return false

func exclude_base() -> bool:
	return exclusivity & Exclusivity.EXCLUDE_BASE

func exclude_below() -> bool:
	return exclusivity & Exclusivity.EXCLUDE_BELOW

func exclude_above() -> bool:
	return exclusivity & Exclusivity.EXCLUDE_ABOVE
