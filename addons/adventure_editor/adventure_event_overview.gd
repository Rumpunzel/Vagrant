@tool
class_name AdventureEventOverview
extends RefCounted

## One plain event at a glance: an entry (shown as a frame) with the pages behind it. Scenarios and encounters are lists of their options
## ([AdventureEventScreen]), not overviews.

class Entry:
	var event: AdventureEvent
	var label: String
	var graph: AdventureEventGraph
	## Shown near where its encounter is ([enum AdventureEvent.Where]), not on the location it is at
	var is_nearby: bool

var root: AdventureEvent
var entries: Array[Entry] = [ ]

func _init(event: AdventureEvent) -> void:
	root = event
	if event == null or event is AdventureEventScenario: return
	var entry: Entry = Entry.new()
	entry.event = event
	entry.is_nearby = event.where == AdventureEvent.Where.NEAR
	entry.label = AdventureGraph.get_title(event) + (" (near)" if entry.is_nearby else "")
	entry.graph = AdventureEventGraph.new(event)
	entries.append(entry)

func get_entry(event: AdventurePage) -> Entry:
	for entry: Entry in entries: if entry.event == event: return entry
	return null

static func get_condition_text(conditions: Array[AdventureCondition]) -> String:
	var texts: Array[String] = [ ]
	for condition: AdventureCondition in conditions:
		if condition != null and not condition.describe().is_empty(): texts.append(condition.describe())
	return ", ".join(texts)

## What the entry's Hide flags hide where it shows: on [param host] (none: any host)
static func get_hiding_text(entry: Entry, host: AdventurePage) -> String:
	if entry.event.exclusivity == 0: return ""
	var where_name: String = AdventureGraph.get_title(host) if host != null else "the host"
	var siblings: Array[AdventureEvent] = [ ]
	if host != null and not entry.is_nearby: siblings = AdventureGraph.get_listed_on(host)
	var index: int = siblings.find(entry.event)
	var before: Array[AdventureEvent] = [ ]
	var after: Array[AdventureEvent] = [ ]
	if index >= 0:
		before = siblings.slice(0, index)
		after = siblings.slice(index + 1)
	var parts: Array[String] = [ ]
	if entry.event.exclude_base(): parts.append("%s's text and decisions" % where_name)
	if entry.event.exclude_above(): parts.append(_name_events("events before it", before, index >= 0))
	if entry.event.exclude_below(): parts.append(_name_events("events after it", after, index >= 0))
	return "Hides %s" % ", ".join(parts)

static func _name_events(text: String, events: Array[AdventureEvent], known: bool) -> String:
	if not known: return text
	return "%s (%s)" % [text, ", ".join(events.map(AdventureGraph.get_title)) if not events.is_empty() else "none"]
