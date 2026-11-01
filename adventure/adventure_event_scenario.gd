@tool
class_name AdventureEventScenario
extends AdventureEvent

## Groups events: shows the first of them whose prerequisites are met (list order is priority), or all of them that are.
## Its own conditions gate the whole group; the events shown act on the location as if they were listed there (also their Hide flags).
## Only the events inside go by [member AdventureEvent.where], not the scenario itself.
## Its title only names it in the editor; the other page fields are unused.

enum Pick {
	## The first that fits
	FIRST,
	## Every one that fits, in order
	ALL,
}

const UNUSED: Array[StringName] = [&"description", &"background", &"ambience", &"decisions", &"text_layering", &"decisions_layering", &"no_rest"]

@export var pick: Pick = Pick.FIRST
@export var events: Array[AdventureEvent]

## Picking the first, the one played from the adventure editor comes first ([method Story.is_forced])
func resolve_events(story: Story, location: AdventureLocation, encounter: AdventureEncounter) -> Array[AdventureEvent]:
	var shown: Array[AdventureEvent] = [ ]
	if pick == Pick.FIRST:
		for event: AdventureEvent in events: if event != null and story.is_forced(event): return event.resolve_events(story, location, encounter)
	for event: AdventureEvent in events:
		if event == null or not event.are_all_prerequisites_fullfilled(story): continue
		shown.append_array(event.resolve_events(story, location, encounter))
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

func get_held_events() -> Array[AdventureEvent]: return events.duplicate()

func find_decision_owner(decision: AdventureDecision) -> AdventurePage:
	for event: AdventureEvent in events:
		var holder: AdventurePage = event.find_decision_owner(decision) if event != null else null
		if holder: return holder
	return null

func _validate_property(property: Dictionary) -> void:
	if UNUSED.has(property.name): property.usage = PROPERTY_USAGE_NO_EDITOR
