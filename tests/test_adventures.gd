class_name TestAdventures
extends RefCounted

## Test-owned helpers for building adventures

## Lists [param events] on [param location], in its own scenario (made if it has none, picking all that fit)
static func list(location: AdventureLocation, events: Array[AdventureEvent]) -> void:
	if location.scenario == null:
		location.scenario = AdventureEventScenario.new()
		location.scenario.pick = AdventureEventScenario.Pick.ALL
	location.scenario.events = events

static func add(location: AdventureLocation, event: AdventureEvent) -> void:
	var events: Array[AdventureEvent] = location.get_own_events()
	events.append(event)
	list(location, events)
