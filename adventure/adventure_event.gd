@tool
class_name AdventureEvent
extends AdventurePage

## Shown on a location while its conditions are met: as one of the location's own events, or an encounter's, by [member where];
## [member text_layering] and [member decisions_layering] decide what else of the page stays

## What an event does to the rest of the page, for its text and for its decisions
enum Layering {
	## It joins the rest
	ADDS,
	## The location's own goes
	REPLACES_LOCATION,
	## Everything else's goes; of two events wanting this, the earlier in the location's order wins and the later one isn't shown
	ONLY_THIS,
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
## What its text does to the area's, the location's and other events' text
@export var text_layering: Layering = Layering.ADDS
## What its decisions do to the location's and other events' decisions
@export var decisions_layering: Layering = Layering.ADDS
## For an encounter's events; a location's own events show there
@export var where: Where = Where.ENCOUNTER
## Only on these locations, or locations in these areas (UIDs); none: no such limit
@export_file("*.tres") var only_at: Array[String]
## Near: how many links from where its encounter is; 0: anywhere in the same area
@export_range(0, MAX_NEARBY_REACH) var nearby_reach: int = 1
## Near: only on locations in the same area as where its encounter is
@export var nearby_stays_in_area: bool = false

## Played from the adventure editor ([method Story.is_forced]): met on that first arrival
func are_all_prerequisites_fullfilled(story: Story) -> bool:
	if story.is_forced(self): return true
	for condition: AdventureCondition in conditions:
		if not condition.is_true(story, self): return false
	return true

## What [param location] shows for this event, once its prerequisites are met: the event itself if it can show there (a scenario: the ones
## it picks); [param encounter]: the encounter it belongs to, none for a location's own events
func resolve_events(story: Story, location: AdventureLocation, encounter: AdventureEncounter) -> Array[AdventureEvent]:
	var shown: Array[AdventureEvent] = [ ]
	if could_show_at(story, location, encounter): shown.append(self)
	return shown

## Whether it could show at [param location] at all, asked before its conditions: a chance is only rolled where what it decides could happen.
## A location's own events (no [param encounter]) always could.
func could_show_at(story: Story, location: AdventureLocation, encounter: AdventureEncounter) -> bool:
	return encounter == null or story.is_forced(self) or can_show_at(story, location, encounter)

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
