@tool
class_name AdventureEventScenario
extends AdventureEvent

## Groups events: shows the first of them whose prerequisites are met (list order is priority), or all of them that are.
## Its own conditions gate the whole group; the events shown act on the location as if they were listed there (also their Hide flags).
## Its title only names it in the editor; the other page fields are unused.

enum Pick {
	## The first that fits
	FIRST,
	## Every one that fits, in order
	ALL,
}

const UNUSED: Array[StringName] = [&"description", &"background", &"ambience", &"decisions", &"exclusivity"]

@export var pick: Pick = Pick.FIRST
@export var events: Array[AdventureEvent]

func resolve_events(story: Story) -> Array[AdventureEvent]:
	var shown: Array[AdventureEvent] = [ ]
	for event: AdventureEvent in events:
		if event == null or not event.are_all_prerequisites_fullfilled(story): continue
		shown.append_array(event.resolve_events(story))
		if pick == Pick.FIRST and not shown.is_empty(): break
	return shown

## Its events, nested scenarios' options included
func get_listed_events() -> Array[AdventureEvent]:
	var listed: Array[AdventureEvent] = [ ]
	for event: AdventureEvent in events:
		if event == null: continue
		listed.append(event)
		if event is AdventureEventScenario: listed.append_array((event as AdventureEventScenario).get_listed_events())
	return listed

func get_held_events() -> Array[AdventureEvent]:
	var held: Array[AdventureEvent] = super()
	held.append_array(events)
	return held

func find_decision_owner(decision: AdventureDecision) -> AdventurePage:
	for event: AdventureEvent in events:
		var holder: AdventurePage = event.find_decision_owner(decision) if event != null else null
		if holder: return holder
	return null

func _validate_property(property: Dictionary) -> void:
	if UNUSED.has(property.name): property.usage = PROPERTY_USAGE_NO_EDITOR
