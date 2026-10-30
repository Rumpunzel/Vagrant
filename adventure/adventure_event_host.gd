@tool
@abstract
class_name AdventureEventHost
extends AdventurePage

## A page that shows events: a location, or an event holding others. Events whose prerequisites are met add their text and decisions,
## and the first of them with a title, background or ambience overrides the host's.

@export var events: Array[AdventureEvent]

func get_page_title(story: Story) -> String:
	for event: AdventureEvent in _get_candidate_events(story):
		var event_title: String = event.get_page_title(story)
		if not event_title.is_empty(): return event_title
	return _get_own_title()

func get_description(story: Story) -> String:
	var active_events: Array[AdventureEvent] = get_events(story)
	var text: String = "" if _is_base_hidden(active_events) else super(story)
	for event: AdventureEvent in active_events: text += event.get_description(story)
	return text

func get_background(story: Story) -> Texture2D:
	for event: AdventureEvent in _get_candidate_events(story):
		var event_background: Texture2D = event.get_background(story)
		if event_background: return event_background
	return super(story)

func get_ambience(story: Story) -> AudioStream:
	for event: AdventureEvent in _get_candidate_events(story):
		var event_ambience: AudioStream = event.get_ambience(story)
		if event_ambience != null: return event_ambience
	return super(story)

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

func get_held_events() -> Array[AdventureEvent]: return events.duplicate()

## Its events, a scenario's options included
func get_listed_events() -> Array[AdventureEvent]:
	var listed: Array[AdventureEvent] = [ ]
	for event: AdventureEvent in events:
		if event == null: continue
		listed.append(event)
		if event is AdventureEventScenario: listed.append_array(event.get_listed_events())
	return listed

func find_decision_owner(decision: AdventureDecision) -> AdventurePage:
	if decisions.has(decision): return self
	for event: AdventureEvent in events:
		var holder: AdventurePage = event.find_decision_owner(decision)
		if holder: return holder
	return null

func _get_own_title() -> String: return title

## Events shown here besides its own (a location's nearby events)
func _get_nearby_events(_story: Story) -> Array[AdventureEvent]:
	var none: Array[AdventureEvent] = [ ]
	return none

## Events whose prerequisites are met, scenarios resolved, in order, then nearby events; before Hide Above / Below
func _get_candidate_events(story: Story) -> Array[AdventureEvent]:
	var candidates: Array[AdventureEvent] = [ ]
	for event: AdventureEvent in events + _get_nearby_events(story):
		if not event.are_all_prerequisites_fullfilled(story): continue
		var shown: AdventureEvent = event.resolve_event(story)
		if shown != null: candidates.append(shown)
	return candidates

## Hide Base on any active event drops this page's own description and decisions
static func _is_base_hidden(active_events: Array[AdventureEvent]) -> bool:
	for event: AdventureEvent in active_events: if event.exclude_base(): return true
	return false
