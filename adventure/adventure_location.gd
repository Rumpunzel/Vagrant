@tool
class_name AdventureLocation
extends AdventurePage

## A place on the map, in an area: what one walks between, where events happen. Events whose prerequisites are met add their text and decisions,
## and the first of them with a title, background or ambience overrides the location's.

@export var area: AdventureArea
## Its own events (usually picking all that fit); stored inside its file
@export var scenario: AdventureEventScenario

func get_page_title(story: Story) -> String:
	for event: AdventureEvent in _get_candidate_events(story):
		var event_title: String = event.get_page_title(story)
		if not event_title.is_empty(): return event_title
	return "%s — %s" % [area.name, title] if area != null else title

func get_description(story: Story) -> String:
	var active_events: Array[AdventureEvent] = get_events(story)
	var text: String = "" if _is_base_hidden(active_events) else super(story)
	for event: AdventureEvent in active_events: text += event.get_description(story)
	return text

func get_background(story: Story) -> Texture2D:
	for event: AdventureEvent in _get_candidate_events(story):
		var event_background: Texture2D = event.get_background(story)
		if event_background: return event_background
	return background

func get_area_background() -> Texture2D:
	return area.background if area else null

func get_ambience(story: Story) -> AudioStream:
	for event: AdventureEvent in _get_candidate_events(story):
		var event_ambience: AudioStream = event.get_ambience(story)
		if event_ambience != null: return event_ambience
	if ambience != null: return ambience
	return area.ambience if area != null else null

func get_decisions(story: Story) -> Array[AdventureDecision]:
	var active_events: Array[AdventureEvent] = get_events(story)
	var active_decisions: Array[AdventureDecision] = [ ]
	for event: AdventureEvent in active_events: active_decisions.append_array(event.get_decisions(story))
	if not _is_base_hidden(active_events): active_decisions.append_array(decisions)
	return active_decisions

## Events whose prerequisites are met, in order. Hide Above drops the ones before an event, Hide Below the ones after it.
func get_events(story: Story) -> Array[AdventureEvent]:
	var active_events: Array[AdventureEvent] = [ ]
	for event: AdventureEvent in _get_candidate_events(story):
		if event.exclude_above(): active_events = [ ]
		active_events.append(event)
		if event.exclude_below(): break
	return active_events

## The events of its own scenario
func get_own_events() -> Array[AdventureEvent]:
	var own: Array[AdventureEvent] = [ ]
	if scenario != null: own.assign(scenario.events)
	return own

## Its own events, scenarios' options included
func get_listed_events() -> Array[AdventureEvent]:
	var listed: Array[AdventureEvent] = [ ]
	if scenario != null: listed = scenario.get_listed_events()
	return listed

func get_held_events() -> Array[AdventureEvent]:
	var held: Array[AdventureEvent] = [ ]
	if scenario != null: held.append(scenario)
	return held

func find_decision_owner(decision: AdventureDecision) -> AdventurePage:
	if decisions.has(decision): return self
	return scenario.find_decision_owner(decision) if scenario != null else null

## [event, its source's location] for every nearby event within reach of this location ([member AdventureEvent.nearby_events])
func find_nearby_events() -> Array[Array]:
	var found: Array[Array] = [ ]
	var own: Array[AdventureEvent] = get_listed_events()
	var distances: Dictionary[AdventureLocation, int] = {self: 0}
	var queue: Array[AdventureLocation] = [self]
	while not queue.is_empty():
		var location: AdventureLocation = queue.pop_front()
		if distances[location] >= AdventureEvent.MAX_NEARBY_REACH: continue
		for linked: AdventureLocation in location.get_linked_locations():
			if distances.has(linked): continue
			distances[linked] = distances[location] + 1
			queue.append(linked)
			for source: AdventureEvent in linked.get_listed_events():
				for nearby: AdventureEvent in source.nearby_events:
					if nearby == null: continue
					if (nearby.nearby_reach == 0 or nearby.nearby_stays_in_area) and linked.area != area: continue
					if nearby.nearby_reach > 0 and distances[linked] > nearby.nearby_reach: continue
					if not own.has(nearby) and not found.any(func(pair: Array) -> bool: return pair[0] == nearby): found.append([nearby, linked])
	return found

## The locations this page's decisions lead to by their plain transition: where one walks to, which is what "nearby" means;
## where a fight or save ends doesn't count (the map draws those as links too)
func get_linked_locations() -> Array[AdventureLocation]:
	var linked: Array[AdventureLocation] = [ ]
	for decision: AdventureDecision in decisions:
		var page: AdventurePage = decision.transition.load_page() if decision != null and decision.transition != null else null
		if page is AdventureLocation and not linked.has(page): linked.append(page as AdventureLocation)
	return linked

## What its own scenario shows (if its conditions are met), then the nearby events that fit; before Hide Above / Below
func _get_candidate_events(story: Story) -> Array[AdventureEvent]:
	var candidates: Array[AdventureEvent] = [ ]
	var sources: Array[AdventureEvent] = story.get_nearby_events(self)
	if scenario != null: sources.push_front(scenario)
	for event: AdventureEvent in sources:
		if event.are_all_prerequisites_fullfilled(story): candidates.append_array(event.resolve_events(story))
	return candidates

## Hide Base on any active event drops this page's own description and decisions
static func _is_base_hidden(active_events: Array[AdventureEvent]) -> bool:
	for event: AdventureEvent in active_events: if event.exclude_base(): return true
	return false
