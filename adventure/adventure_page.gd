@tool
class_name AdventurePage
extends AdventurePageReference

enum Exclusivity {
	NONE = 0,
	EXCLUDE_BASE = 1,
	EXCLUDE_BELOW = 2,
	EXCLUDE_ABOVE = 4,
}

## How far nearby events are looked for, also for a reach of the whole area
const MAX_NEARBY_REACH: int = 8

@export_placeholder("Title") var title: String
@export_multiline var description: String
@export var area: AdventureArea
@export var background: Texture2D
@export var ambience: AudioStream
@export var conditions: Array[AdventureCondition]
@export var decisions: Array[AdventureDecision]
@export_flags("Hide Base:1", "Hide Below:2", "Hide Above:4", "Hide All:7")
var exclusivity: int = 0
@export var events: Array[AdventurePage]
## Each host gets its own of what this event spawns (monsters); otherwise all hosts share them
@export var generic: bool = false
## Events shown around the locations this event is on (Hearing Eleanor around the Eleanor scenario), each within its [member nearby_reach],
## when their own conditions are met
@export var nearby_events: Array[AdventurePage]
## As a nearby event: how many links from its source's locations it shows; 0: anywhere in the same area
@export_range(0, MAX_NEARBY_REACH) var nearby_reach: int = 1

func are_all_prerequisites_fullfilled(story: Story) -> bool:
	for condition: AdventureCondition in conditions:
		if not condition.is_true(story, self): return false
	return true

func prepare() -> void: pass

func get_page_title(story: Story) -> String:
	for event: AdventurePage in _get_candidate_events(story):
		var event_title: String = event.get_page_title(story)
		if not event_title.is_empty(): return event_title
	if area == null: return "%s" % title if not title.is_empty() else ""
	return "%s — %s" % [area.name, title]

func get_description(story: Story) -> String:
	var active_events: Array[AdventurePage] = get_events(story)
	var text: String = "" if _is_base_hidden(active_events) else "[p]%s[/p]" % description
	for event: AdventurePage in active_events: text += event.get_description(story)
	return text

func get_background(story: Story) -> Texture2D:
	for event: AdventurePage in _get_candidate_events(story):
		var event_background: Texture2D = event.get_background(story)
		if event_background: return event_background
	return background

func get_area_background() -> Texture2D:
	return area.background if area else null

func get_ambience(story: Story) -> AudioStream:
	for event: AdventurePage in _get_candidate_events(story):
		var event_ambience: AudioStream = event.get_ambience(story)
		if event_ambience != null: return event_ambience
	var area_ambience: AudioStream = area.ambience if area != null else null
	return ambience if ambience != null else area_ambience

func get_decisions(story: Story) ->  Array[AdventureDecision]:
	var active_events: Array[AdventurePage] = get_events(story)
	var active_decisions: Array[AdventureDecision] = [ ]
	for event: AdventurePage in active_events: active_decisions.append_array(event.get_decisions(story))
	if not _is_base_hidden(active_events): active_decisions.append_array(decisions)
	return active_decisions

## Events whose prerequisites are met, in order. Hide Above drops the ones before an event, Hide Below the ones after it.
func get_events(story: Story) -> Array[AdventurePage]:
	var active_events: Array[AdventurePage] = [ ]
	for event: AdventurePage in _get_candidate_events(story):
		if event.exclude_above(): active_events = [ ]
		active_events.append(event)
		if event.exclude_below(): break
	return active_events

## What a host shows for this event, once its prerequisites are met: the event itself (a scenario: one of its events or none)
func resolve_event(_story: Story) -> AdventurePage: return self

## [event, its source's location] for every nearby event within reach of this location ([member nearby_events]); none for pages without an area
func find_nearby_events() -> Array[Array]:
	var found: Array[Array] = [ ]
	if area == null: return found
	var distances: Dictionary[AdventurePage, int] = {self: 0}
	var queue: Array[AdventurePage] = [self]
	while not queue.is_empty():
		var location: AdventurePage = queue.pop_front()
		if distances[location] >= MAX_NEARBY_REACH: continue
		for linked: AdventurePage in location.get_linked_locations():
			if distances.has(linked): continue
			distances[linked] = distances[location] + 1
			queue.append(linked)
			for source: AdventurePage in linked.get_listed_events():
				for nearby: AdventurePage in source.nearby_events:
					if nearby == null: continue
					var in_reach: bool = distances[linked] <= nearby.nearby_reach if nearby.nearby_reach > 0 else linked.area == area
					if in_reach and not events.has(nearby) and not found.any(func(pair: Array) -> bool: return pair[0] == nearby): found.append([nearby, linked])
	return found

## This page and the pages (and events) it holds directly, not through transitions or host links: what its file stores with it
func get_held_pages() -> Array[AdventurePage]:
	var held: Array[AdventurePage] = [ ]
	var queue: Array[AdventurePage] = [self]
	while not queue.is_empty():
		var page: AdventurePage = queue.pop_front()
		if page == null or held.has(page): continue
		held.append(page)
		queue.append_array(page.events)
		queue.append_array(page.nearby_events)
		for decision: AdventureDecision in page.decisions:
			if decision == null: continue
			for reference: AdventurePageReference in decision.get_page_references(): if reference is AdventurePage: queue.append(reference as AdventurePage)
	return held

## The locations (pages with an area) this page's decisions lead to by their plain transition: where one walks to, which is what "nearby" means;
## where a fight or save ends doesn't count (the map draws those as links too)
func get_linked_locations() -> Array[AdventurePage]:
	var linked: Array[AdventurePage] = [ ]
	for decision: AdventureDecision in decisions:
		var page: AdventurePage = decision.transition.load_page() if decision != null and decision.transition != null else null
		if page != null and page.area != null and not linked.has(page): linked.append(page)
	return linked

## Its events, a scenario's options included
func get_listed_events() -> Array[AdventurePage]:
	var listed: Array[AdventurePage] = [ ]
	for event: AdventurePage in events:
		if event == null: continue
		listed.append(event)
		if event is AdventureEventScenario: listed.append_array(event.get_listed_events())
	return listed

## Events whose prerequisites are met, scenarios resolved, in order, then nearby events; before Hide Above / Below
func _get_candidate_events(story: Story) -> Array[AdventurePage]:
	var candidates: Array[AdventurePage] = [ ]
	for event: AdventurePage in events + story.get_nearby_events(self):
		if not event.are_all_prerequisites_fullfilled(story): continue
		var shown: AdventurePage = event.resolve_event(story)
		if shown != null: candidates.append(shown)
	return candidates

## Hide Base on any active event drops this page's own description and decisions
static func _is_base_hidden(active_events: Array[AdventurePage]) -> bool:
	for event: AdventurePage in active_events: if event.exclude_base(): return true
	return false

func exclude_base() -> bool:
	return exclusivity & Exclusivity.EXCLUDE_BASE

func exclude_below() -> bool:
	return exclusivity & Exclusivity.EXCLUDE_BELOW

func exclude_above() -> bool:
	return exclusivity & Exclusivity.EXCLUDE_ABOVE

## The page (this one or a nested event) that defines [param decision], since [method get_decisions] flattens events
func find_decision_owner(decision: AdventureDecision) -> AdventurePage:
	if decisions.has(decision): return self
	for event: AdventurePage in events:
		var owner: AdventurePage = event.find_decision_owner(decision)
		if owner: return owner
	return null

func get_adventure_page() -> AdventurePage:
	return self
