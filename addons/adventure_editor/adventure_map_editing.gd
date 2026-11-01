@tool
class_name AdventureMapEditing
extends RefCounted

## Map edits as data (the changes they make), apart from undo and saving in [AdventureEditor], so they can be tested; new things: [AdventureMakers]

## [param page]'s decisions without the plain ones leading to [param to]; fights and saves stay
static func without_links(page: AdventurePage, to: AdventurePage) -> Array[AdventureDecision]:
	var kept: Array[AdventureDecision] = [ ]
	for decision: AdventureDecision in page.decisions:
		var leads_there: bool = decision != null and decision.transition != null and decision.transition.get_adventure_page() == to
		if not leads_there or decision is AdventureDiceDecision: kept.append(decision)
	return kept

## Changes putting [param event] at [param location]: an encounter could be there too, another event is listed there; none if it is already
static func get_changes_putting(location: AdventureLocation, event: AdventureEvent) -> Array[Array]:
	if event is AdventureEncounter: return get_changes_placing(event as AdventureEncounter, location, true)
	var events: Array[AdventureEvent] = location.get_own_events()
	if events.has(event): return [ ]
	events.append(event)
	return AdventureEventEditing.get_changes_listing(location, events)

## Changes taking [param event] off [param location]'s own events
static func get_changes_removing(location: AdventureLocation, event: AdventureEvent) -> Array[Array]:
	var events: Array[AdventureEvent] = location.get_own_events()
	if not events.has(event): return [ ]
	events.erase(event)
	return AdventureEventEditing.get_changes_listing(location, events)

## Changes making [param location] one of the places [param encounter] could be ([param here]), or not; none if it is so already
static func get_changes_placing(encounter: AdventureEncounter, location: AdventureLocation, here: bool) -> Array[Array]:
	var key: String = AdventureLayout.get_key(location)
	var places: Array[String] = encounter.places.duplicate()
	if here == places.has(key): return [ ]
	if here: places.append(key)
	else: places.erase(key)
	return [[encounter, &"places", places, encounter]]

