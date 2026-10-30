@tool
class_name AdventureLocation
extends AdventurePage

## A place on the map, in an area: what one walks between, where events happen. Events whose prerequisites are met add their text and decisions,
## and the first of them with a title, background or ambience overrides the location's.

@export var area: AdventureArea
## Its own events (usually picking all that fit); stored inside its file
@export var scenario: AdventureEventScenario
## Shown instead of [member AdventurePage.description] on the first visit
@export_multiline var first_description: String
@export var tracks: Array[AdventureStageTrack]
## What shows first (Hide Above / Below go by it): encounters by UID, and this location itself for its own events;
## unlisted, its own events come first and other encounters last, in the adventure's order
@export_file("*.tres") var order: Array[String]

func get_page_title(story: Story) -> String:
	for event: AdventureEvent in _get_candidate_events(story):
		var event_title: String = event.get_page_title(story)
		if not event_title.is_empty(): return event_title
	return "%s — %s" % [area.name, title] if area != null else title

func get_description(story: Story) -> String:
	var active_events: Array[AdventureEvent] = get_events(story)
	var own: String = first_description if not first_description.is_empty() and story.get_how_often_page_has_been_entered(self) == 0 else description
	var text: String = "" if _is_base_hidden(active_events) else "[p]%s[/p]" % own
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

## Links from here to the locations within [constant AdventureEvent.MAX_NEARBY_REACH] links of plain transitions
func get_distances() -> Dictionary[AdventureLocation, int]:
	var distances: Dictionary[AdventureLocation, int] = {self: 0}
	var queue: Array[AdventureLocation] = [self]
	while not queue.is_empty():
		var location: AdventureLocation = queue.pop_front()
		if distances[location] >= AdventureEvent.MAX_NEARBY_REACH: continue
		for linked: AdventureLocation in location.get_linked_locations():
			if distances.has(linked): continue
			distances[linked] = distances[location] + 1
			queue.append(linked)
	return distances

## Its own scenario and [param encounters], in its [member order]
func get_sources(encounters: Array[AdventureEncounter]) -> Array[AdventureEvent]:
	var sources: Array[AdventureEvent] = [ ]
	var own_listed: bool = false
	for entry: String in order:
		var source: Resource = Files.load_existing(entry)
		if source == self:
			own_listed = true
			if scenario != null: sources.append(scenario)
		elif source is AdventureEncounter and encounters.has(source) and not sources.has(source): sources.append(source as AdventureEncounter)
	if not own_listed and scenario != null: sources.push_front(scenario)
	for encounter: AdventureEncounter in encounters: if not sources.has(encounter): sources.append(encounter)
	return sources

## The locations this page's decisions lead to by their plain transition: where one walks to, which is what "nearby" means;
## where a fight or save ends doesn't count (the map draws those as links too)
func get_linked_locations() -> Array[AdventureLocation]:
	var linked: Array[AdventureLocation] = [ ]
	for decision: AdventureDecision in decisions:
		var page: AdventurePage = decision.transition.load_page() if decision != null and decision.transition != null else null
		if page is AdventureLocation and not linked.has(page): linked.append(page as AdventureLocation)
	return linked

## What its own scenario and the encounters show here (each if its conditions are met), in its order; before Hide Above / Below
func _get_candidate_events(story: Story) -> Array[AdventureEvent]:
	var candidates: Array[AdventureEvent] = [ ]
	for source: AdventureEvent in get_sources(story.world.get_encounters()):
		if source.are_all_prerequisites_fullfilled(story): candidates.append_array(source.resolve_events(story, self, null))
	return candidates

## Hide Base on any active event drops this page's own description and decisions
static func _is_base_hidden(active_events: Array[AdventureEvent]) -> bool:
	for event: AdventureEvent in active_events: if event.exclude_base(): return true
	return false
