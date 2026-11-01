@tool
class_name AdventureLocation
extends AdventurePage

## A place on the map, in an area: what one walks between, where events happen. Its page reads: the area's text (entering it), its own text,
## then the events whose prerequisites are met in its order (its own, the encounters'), each adding to, replacing the location's or being the only
## text and decisions ([enum AdventureEvent.Layering]); the first with a title, background or ambience overrides the location's.

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
	for event: AdventureEvent in get_events(story):
		var event_title: String = event.get_page_title(story)
		if not event_title.is_empty(): return event_title
	return "%s — %s" % [area.name, title] if area != null else title

func get_description(story: Story) -> String:
	var active_events: Array[AdventureEvent] = get_events(story)
	var only: AdventureEvent = _find_layering(active_events, &"text_layering", AdventureEvent.Layering.ONLY_THIS)
	if only != null: return only.get_description(story)
	var own: String = first_description if not first_description.is_empty() and story.get_how_often_page_has_been_entered(self) == 0 else description
	var text: String = story.get_area_text(self)
	if _find_layering(active_events, &"text_layering", AdventureEvent.Layering.REPLACES_LOCATION) == null: text += "[p]%s[/p]" % own
	for event: AdventureEvent in active_events: text += event.get_description(story)
	return text

func get_background(story: Story) -> Texture2D:
	for event: AdventureEvent in get_events(story):
		var event_background: Texture2D = event.get_background(story)
		if event_background: return event_background
	return background

func get_area_background() -> Texture2D:
	return area.background if area else null

func get_ambience(story: Story) -> AudioStream:
	for event: AdventureEvent in get_events(story):
		var event_ambience: AudioStream = event.get_ambience(story)
		if event_ambience != null: return event_ambience
	if ambience != null: return ambience
	return area.ambience if area != null else null

func get_decisions(story: Story) -> Array[AdventureDecision]:
	var active_events: Array[AdventureEvent] = get_events(story)
	var only: AdventureEvent = _find_layering(active_events, &"decisions_layering", AdventureEvent.Layering.ONLY_THIS)
	if only != null: return only.get_decisions(story)
	var active_decisions: Array[AdventureDecision] = [ ]
	for event: AdventureEvent in active_events: active_decisions.append_array(event.get_decisions(story))
	if _find_layering(active_events, &"decisions_layering", AdventureEvent.Layering.REPLACES_LOCATION) == null: active_decisions.append_array(decisions)
	return active_decisions

## Events whose prerequisites are met, in order; of two wanting to be the only text (or the only decisions), the later isn't shown
func get_events(story: Story) -> Array[AdventureEvent]:
	var active_events: Array[AdventureEvent] = [ ]
	for event: AdventureEvent in _get_candidate_events(story):
		var only_text: bool = event.text_layering == AdventureEvent.Layering.ONLY_THIS
		var only_decisions: bool = event.decisions_layering == AdventureEvent.Layering.ONLY_THIS
		if only_text and _find_layering(active_events, &"text_layering", AdventureEvent.Layering.ONLY_THIS) != null: continue
		if only_decisions and _find_layering(active_events, &"decisions_layering", AdventureEvent.Layering.ONLY_THIS) != null: continue
		active_events.append(event)
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

## [param encounters] in its [member order], with none in the slot of its own events
func get_slots(encounters: Array[AdventureEncounter]) -> Array[AdventureEncounter]:
	var slots: Array[AdventureEncounter] = [ ]
	var own_listed: bool = false
	for entry: String in order:
		var source: Resource = Files.load_existing(entry)
		if source == self and not own_listed:
			own_listed = true
			slots.append(null)
		elif source is AdventureEncounter and encounters.has(source) and not slots.has(source): slots.append(source as AdventureEncounter)
	if not own_listed: slots.push_front(null)
	for encounter: AdventureEncounter in encounters: if not slots.has(encounter): slots.append(encounter)
	return slots

## Its own scenario and [param encounters], in its [member order]
func get_sources(encounters: Array[AdventureEncounter]) -> Array[AdventureEvent]:
	var sources: Array[AdventureEvent] = [ ]
	for slot: AdventureEncounter in get_slots(encounters):
		if slot != null: sources.append(slot)
		elif scenario != null: sources.append(scenario)
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

## The first of [param active_events] whose [param property] (text or decisions layering) is [param layering]
static func _find_layering(active_events: Array[AdventureEvent], property: StringName, layering: AdventureEvent.Layering) -> AdventureEvent:
	for event: AdventureEvent in active_events: if event.get(property) == layering: return event
	return null
