@tool
class_name AdventureEvent
extends AdventurePage

## Shown on the locations listing it (and around them, as a nearby event) while its conditions are met; [member exclusivity] decides
## what else stays visible

enum Exclusivity {
	NONE = 0,
	EXCLUDE_BASE = 1,
	EXCLUDE_BELOW = 2,
	EXCLUDE_ABOVE = 4,
}

## How far nearby events are looked for, also for a reach of the whole area
const MAX_NEARBY_REACH: int = 8

@export var conditions: Array[AdventureCondition]
@export_flags("Hide Base:1", "Hide Below:2", "Hide Above:4", "Hide All:7")
var exclusivity: int = 0
## Each host gets its own of what this event spawns (monsters); otherwise all hosts share them
@export var generic: bool = false
## Events shown around the locations this event is on (Hearing Eleanor around the Eleanor scenario), each within its [member nearby_reach],
## when their own conditions are met
@export var nearby_events: Array[AdventureEvent]
## As a nearby event: how many links from its source's locations it shows; 0: anywhere in the same area
@export_range(0, MAX_NEARBY_REACH) var nearby_reach: int = 1
## As a nearby event: only on locations in the same area as its source's location
@export var nearby_stays_in_area: bool = false

func are_all_prerequisites_fullfilled(story: Story) -> bool:
	for condition: AdventureCondition in conditions:
		if not condition.is_true(story, self): return false
	return true

## What a location shows for this event, once its prerequisites are met: the event itself (a scenario: the ones it picks)
func resolve_events(_story: Story) -> Array[AdventureEvent]:
	var shown: Array[AdventureEvent] = [self]
	return shown

func get_held_events() -> Array[AdventureEvent]:
	return nearby_events.duplicate()

func exclude_base() -> bool:
	return exclusivity & Exclusivity.EXCLUDE_BASE

func exclude_below() -> bool:
	return exclusivity & Exclusivity.EXCLUDE_BELOW

func exclude_above() -> bool:
	return exclusivity & Exclusivity.EXCLUDE_ABOVE
