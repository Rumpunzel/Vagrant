@tool
class_name AdventureEventOverview
extends RefCounted

## Everything inside one event at a glance: an entry (shown as a frame) for the event, or a switch for a scenario with an entry per option,
## and the same again for every sub-event of the pages inside, recursively

class Entry:
	var event: AdventurePage
	var label: String
	var graph: AdventureEventGraph
	## What the page above lists for it: the event, or the outermost scenario it is an option of
	var listed_as: AdventurePage
	## The entry and page whose events list it; none for the overview's own event
	var parent: Entry
	var parent_page: AdventurePage
	## The scenario it is an option of, if any
	var switch: Switch

## A scenario choosing one of its options: the first whose conditions are met
class Switch:
	var scenario: AdventureEventScenario
	var listed_as: AdventurePage
	var parent: Entry
	var parent_page: AdventurePage
	## The scenario this one is an option of, if any
	var outer: Switch

var root: AdventurePage
var entries: Array[Entry] = [ ]
var switches: Array[Switch] = [ ]

var _seen: Array[AdventurePage] = [ ]

func _init(event: AdventurePage) -> void:
	root = event
	_add(event, event, null, null, null)

func get_entry(event: AdventurePage) -> Entry:
	for entry: Entry in entries: if entry.event == event: return entry
	return null

## The first entry for what a page lists as [param event] (a scenario: its first option)
func get_listed_entry(event: AdventurePage) -> Entry:
	for entry: Entry in entries: if entry.listed_as == event or entry.event == event: return entry
	return null

func get_switch(scenario: AdventurePage) -> Switch:
	for switch: Switch in switches: if switch.scenario == scenario: return switch
	return null

static func get_condition_text(conditions: Array[AdventureCondition]) -> String:
	var texts: Array[String] = [ ]
	for condition: AdventureCondition in conditions:
		if condition != null and not condition.describe().is_empty(): texts.append(condition.describe())
	return ", ".join(texts)

## What the entry's Hide flags hide where it is listed: on [param host] (none: any host) or, for a sub-event, on its page
static func get_hiding_text(entry: Entry, host: AdventurePage) -> String:
	if entry.event.exclusivity == 0: return ""
	var where: AdventurePage = entry.parent_page if entry.parent_page != null else host
	var where_name: String = AdventureGraph.get_title(where) if where != null else "the host"
	var siblings: Array[AdventurePage] = [ ]
	if where != null: siblings = where.events
	var index: int = siblings.find(entry.listed_as)
	var before: Array[AdventurePage] = [ ]
	var after: Array[AdventurePage] = [ ]
	if index >= 0:
		before = siblings.slice(0, index)
		after = siblings.slice(index + 1)
	var parts: Array[String] = [ ]
	if entry.event.exclude_base(): parts.append("%s's text and decisions" % where_name)
	if entry.event.exclude_above(): parts.append(_name_events("events before it", before, index >= 0))
	if entry.event.exclude_below(): parts.append(_name_events("events after it", after, index >= 0))
	return "Hides %s" % ", ".join(parts)

static func get_monster_text(entry: Entry) -> String:
	if entry.event.generic: return "Monsters: one per host"
	for page: AdventurePage in entry.graph.pages:
		if page.decisions.any(func(decision: AdventureDecision) -> bool: return decision is AdventureFightDecision): return "Monsters: shared by all hosts"
	return ""

static func _name_events(text: String, events: Array[AdventurePage], known: bool) -> String:
	if not known: return text
	return "%s (%s)" % [text, ", ".join(events.map(AdventureGraph.get_title)) if not events.is_empty() else "none"]

func _add(event: AdventurePage, listed_as: AdventurePage, parent: Entry, parent_page: AdventurePage, switch: Switch) -> void:
	if event == null or _seen.has(event): return
	_seen.append(event)
	if event is AdventureEventScenario:
		var inner: Switch = Switch.new()
		inner.scenario = event as AdventureEventScenario
		inner.listed_as = listed_as
		inner.parent = parent
		inner.parent_page = parent_page
		inner.outer = switch
		switches.append(inner)
		for option: AdventurePage in event.events: _add(option, listed_as, parent, parent_page, inner)
		return
	var entry: Entry = Entry.new()
	entry.event = event
	entry.label = AdventureGraph.get_title(event)
	entry.graph = AdventureEventGraph.new(event)
	entry.listed_as = listed_as
	entry.parent = parent
	entry.parent_page = parent_page
	entry.switch = switch
	entries.append(entry)
	for page: AdventurePage in entry.graph.pages:
		for nested: AdventurePage in page.events: _add(nested, nested, entry, page, null)
