@tool
class_name AdventureEventOverview
extends RefCounted

## Everything inside one event at a glance: an entry (shown as a frame) for the event, or for each option of a scenario in priority order,
## and the same again for every sub-event of the pages inside, recursively

class Entry:
	var event: AdventurePage
	var label: String
	## When it shows: its own conditions, a scenario option's also those of its scenarios
	var conditions: Array[AdventureCondition]
	var graph: AdventureEventGraph
	## What the page above lists for it: the event, or the outermost scenario it is an option of
	var listed_as: AdventurePage
	## The entry and page whose events list it; none for the overview's own event
	var parent: Entry
	var parent_page: AdventurePage

var root: AdventurePage
var entries: Array[Entry] = [ ]

var _seen: Array[AdventurePage] = [ ]

func _init(event: AdventurePage) -> void:
	root = event
	_add(event, event, "", [ ], null, null)

func get_entry(event: AdventurePage) -> Entry:
	for entry: Entry in entries: if entry.event == event: return entry
	return null

## The first entry for what a page lists as [param event] (a scenario: its first option)
func get_listed_entry(event: AdventurePage) -> Entry:
	for entry: Entry in entries: if entry.listed_as == event or entry.event == event: return entry
	return null

static func get_condition_text(entry: Entry) -> String:
	var texts: Array[String] = [ ]
	for condition: AdventureCondition in entry.conditions:
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

func _add(event: AdventurePage, listed_as: AdventurePage, prefix: String, conditions: Array[AdventureCondition], parent: Entry, parent_page: AdventurePage) -> void:
	if event == null or _seen.has(event): return
	_seen.append(event)
	var all_conditions: Array[AdventureCondition] = conditions.duplicate()
	all_conditions.append_array(event.conditions)
	if event is AdventureEventScenario:
		var scenario_name: String = AdventureGraph.get_title(event)
		for index: int in event.events.size():
			_add(event.events[index], listed_as, "%s%s %d · " % [prefix, scenario_name, index + 1], all_conditions, parent, parent_page)
		return
	var entry: Entry = Entry.new()
	entry.event = event
	entry.label = prefix + AdventureGraph.get_title(event)
	entry.conditions = all_conditions
	entry.graph = AdventureEventGraph.new(event)
	entry.listed_as = listed_as
	entry.parent = parent
	entry.parent_page = parent_page
	entries.append(entry)
	for page: AdventurePage in entry.graph.pages:
		for nested: AdventurePage in page.events: _add(nested, nested, "", [ ], entry, page)
