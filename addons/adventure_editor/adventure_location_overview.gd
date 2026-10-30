@tool
class_name AdventureLocationOverview
extends RefCounted

## What can happen at one location, worked out from the content (not from a running story): its own events and the encounters that can show
## there, in its order (Hide Above / Below go by it), and the encounters a move consequence can bring there.

class Section:
	## None: the location's own events
	var encounter: AdventureEncounter
	## Why it can show here: "its own events", "could be here", "near it", "anywhere", "can come here"
	var reason: String
	## The events that could show here (scenarios' options, not the scenarios)
	var events: Array[AdventureEvent] = [ ]

class Arrival:
	var encounter: AdventureEncounter
	## The page (an event, or a page behind it) whose decision brings it here
	var page: AdventurePage
	var decision: AdventureDecision

var location: AdventureLocation
var sections: Array[Section] = [ ]
var arrivals: Array[Arrival] = [ ]

## [param pages]: other pages whose decisions may bring encounters here (the map's); encounters' own events are looked at anyway
func _init(at: AdventureLocation, encounters: Array[AdventureEncounter], pages: Array[AdventurePage] = [ ]) -> void:
	location = at
	for encounter: AdventureEncounter in encounters:
		for event: AdventureEvent in encounter.get_listed_events(): _find_arrivals(event, encounter)
	for page: AdventurePage in pages:
		_find_arrivals_on(page, null)
		if page is AdventureLocation: for event: AdventureEvent in (page as AdventureLocation).get_listed_events(): _find_arrivals(event, null)
	for slot: AdventureEncounter in at.get_slots(encounters):
		if slot != null: _add_encounter(slot)
		else: sections.append(_make_own())

## The keys for [member AdventureLocation.order] with the section at [param index] moved by [param step]
func get_order_moving(index: int, step: int) -> Array[String]:
	var keys: Array[String] = [ ]
	for section: Section in sections: keys.append(AdventureLayout.get_key(section.encounter if section.encounter != null else location))
	var key: String = keys.pop_at(index)
	keys.insert(clampi(index + step, 0, keys.size()), key)
	return keys

func _make_own() -> Section:
	var section: Section = Section.new()
	section.reason = "its own events"
	for event: AdventureEvent in location.get_listed_events(): if not event is AdventureEventScenario: section.events.append(event)
	return section

func _add_encounter(encounter: AdventureEncounter) -> void:
	var section: Section = Section.new()
	section.encounter = encounter
	var reasons: Array[String] = [ ]
	for event: AdventureEvent in encounter.get_listed_events():
		if event is AdventureEventScenario: continue
		var reason: String = _get_reason(event, encounter)
		if reason.is_empty(): continue
		section.events.append(event)
		if not reasons.has(reason): reasons.append(reason)
	section.reason = ", ".join(reasons)
	if not section.events.is_empty(): sections.append(section)

## Why [param event] of [param encounter] could show here; empty: it can't
func _get_reason(event: AdventureEvent, encounter: AdventureEncounter) -> String:
	if not event.only_at.is_empty() and not event.is_allowed_at(location): return ""
	var places: Array[AdventureLocation] = encounter.get_places()
	match event.where:
		AdventureEvent.Where.ANYWHERE: return "anywhere"
		AdventureEvent.Where.ENCOUNTER:
			if places.has(location): return "could be here"
			return "can come here" if arrivals.any(func(arrival: Arrival) -> bool: return arrival.encounter == encounter) else ""
	return "near it" if not places.has(location) and places.any(_is_near.bind(event)) else ""

func _is_near(place: AdventureLocation, event: AdventureEvent) -> bool:
	var distances: Dictionary[AdventureLocation, int] = place.get_distances()
	if not distances.has(location): return false
	if (event.nearby_reach == 0 or event.nearby_stays_in_area) and location.area != place.area: return false
	return event.nearby_reach == 0 or distances[location] <= event.nearby_reach

## Move consequences in [param event] and the pages behind it sending an encounter here; [param encounter]: whose event it is (for an empty one)
func _find_arrivals(event: AdventureEvent, encounter: AdventureEncounter) -> void:
	for page: AdventurePage in AdventureEventGraph.new(event).pages: _find_arrivals_on(page, encounter)

func _find_arrivals_on(page: AdventurePage, encounter: AdventureEncounter) -> void:
	for decision: AdventureDecision in page.decisions:
		if decision == null: continue
		for outcome: AdventureDecision.Outcome in decision.get_outcomes():
			for consequence: AdventureConsequence in decision.get_consequences_of(outcome):
				var move: AdventureMoveConsequence = consequence as AdventureMoveConsequence
				if move == null or move.to.is_empty() or Files.load_existing(move.to) != location: continue
				var arrival: Arrival = Arrival.new()
				arrival.encounter = Files.load_existing(move.encounter) as AdventureEncounter if not move.encounter.is_empty() else encounter
				arrival.page = page
				arrival.decision = decision
				if arrival.encounter != null: arrivals.append(arrival)
