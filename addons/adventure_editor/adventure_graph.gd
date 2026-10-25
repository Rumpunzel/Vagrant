@tool
class_name AdventureGraph
extends RefCounted

## The map of one adventure, found by walking its links from the starting page: pages that are nodes, their areas and the links between them.
## Nodes are the pages reached through pages' own decisions (locations, and pages without an area outside the area frames).
## Events and the pages behind them are no nodes; a location reached through them is linked from the event's host, marked [member Link.through_event].

class Link:
	var from: AdventurePage
	var to: AdventurePage
	var through_event: bool

	func _init(from_page: AdventurePage, to_page: AdventurePage, is_through_event: bool) -> void:
		from = from_page
		to = to_page
		through_event = is_through_event

var pages: Array[AdventurePage] = [ ]
var areas: Array[AdventureArea] = [ ]
var links: Array[Link] = [ ]
## Every event met on the walk (also nested ones and those of pages behind events), in order, with the pages listing it in their events
var event_hosts: Dictionary[AdventurePage, Array] = {}

func _init(adventure: Adventure) -> void:
	if adventure == null or adventure.starting_page == null: return
	var queue: Array[AdventurePage] = [adventure.starting_page]
	while not queue.is_empty():
		var page: AdventurePage = queue.pop_front()
		if pages.has(page): continue
		pages.append(page)
		if page.area != null and not areas.has(page.area): areas.append(page.area)
		for target: AdventurePage in _get_targets(page.decisions):
			_add_link(page, target, false)
			queue.append(target)
		for target: AdventurePage in _get_event_targets(page):
			_add_link(page, target, true)
			queue.append(target)

static func get_title(page: AdventurePage) -> String:
	return page.title if not page.title.is_empty() else page.resource_path.get_file().get_basename().capitalize()

## Page references of [param decision] by property name, [code]transition[/code] first.
## Every [AdventurePageReference] property counts (failure, flee, draw ...), so new decision kinds need no change here;
## read through the property list, since decision scripts aren't @tool and are only placeholders in the editor.
static func get_references(decision: AdventureDecision) -> Dictionary[StringName, AdventurePageReference]:
	var references: Dictionary[StringName, AdventurePageReference] = {}
	if decision.transition != null: references[&"transition"] = decision.transition
	for property: Dictionary in decision.get_property_list():
		if not property.usage & PROPERTY_USAGE_STORAGE or property.name == &"transition": continue
		var value: Variant = decision.get(property.name)
		if value is AdventurePageReference: references[StringName(property.name)] = value
	return references

func get_link(from: AdventurePage, to: AdventurePage) -> Link:
	for link: Link in links: if link.from == from and link.to == to: return link
	return null

func get_hosts(event: AdventurePage) -> Array[AdventurePage]:
	var hosts: Array[AdventurePage] = [ ]
	hosts.assign(event_hosts.get(event, [ ]))
	return hosts

## The map pages [param event] happens on, also through the events (and scenarios) it is part of
func get_location_hosts(event: AdventurePage) -> Array[AdventurePage]:
	var locations: Array[AdventurePage] = [ ]
	var queue: Array[AdventurePage] = get_hosts(event)
	var seen: Array[AdventurePage] = [ ]
	while not queue.is_empty():
		var host: AdventurePage = queue.pop_front()
		if seen.has(host): continue
		seen.append(host)
		if pages.has(host): locations.append(host)
		else: queue.append_array(get_hosts(host))
	return locations

## Events listed on map pages, in the order met
func get_top_events() -> Array[AdventurePage]:
	var top: Array[AdventurePage] = [ ]
	for event: AdventurePage in event_hosts:
		if get_hosts(event).any(func(host: AdventurePage) -> bool: return pages.has(host)): top.append(event)
	return top

## A page linked both directly and through an event counts as linked directly
func _add_link(from: AdventurePage, to: AdventurePage, through_event: bool) -> void:
	if from == to: return
	var link: Link = get_link(from, to)
	if link == null: links.append(Link.new(from, to, through_event))
	elif not through_event: link.through_event = false

## Locations reached from [param host]'s events, also through (nested) events and pages without an area behind them
func _get_event_targets(host: AdventurePage) -> Array[AdventurePage]:
	var hidden: Array[AdventurePage] = [ ]
	_add_events(host, hidden)
	var targets: Array[AdventurePage] = [ ]
	var index: int = 0
	while index < hidden.size():
		var page: AdventurePage = hidden[index]
		index += 1
		_add_events(page, hidden)
		for target: AdventurePage in _get_targets(page.decisions):
			if target.area != null: targets.append(target)
			elif not hidden.has(target): hidden.append(target)
	return targets

func _add_events(host: AdventurePage, hidden: Array[AdventurePage]) -> void:
	for event: AdventurePage in host.events:
		if not event_hosts.has(event): event_hosts[event] = [ ]
		if not event_hosts[event].has(host): event_hosts[event].append(host)
		if not hidden.has(event): hidden.append(event)

## Pages the decisions lead to; host references lead nowhere outside the story
static func _get_targets(decisions: Array[AdventureDecision]) -> Array[AdventurePage]:
	var targets: Array[AdventurePage] = [ ]
	for decision: AdventureDecision in decisions:
		if decision == null: continue
		for reference: AdventurePageReference in get_references(decision).values():
			var target: AdventurePage = reference.get_adventure_page()
			if target != null: targets.append(target)
	return targets
