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

func _init(adventure: Adventure) -> void:
	if adventure == null or adventure.starting_page == null: return
	var queue: Array[AdventurePage] = [adventure.starting_page]
	while not queue.is_empty():
		var page: AdventurePage = queue.pop_front()
		if pages.has(page): continue
		pages.append(page)
		if page._area != null and not areas.has(page._area): areas.append(page._area)
		for target: AdventurePage in _get_targets(page._decisions):
			_add_link(page, target, false)
			queue.append(target)
		for target: AdventurePage in _get_event_targets(page):
			_add_link(page, target, true)
			queue.append(target)

static func get_title(page: AdventurePage) -> String:
	return page._title if not page._title.is_empty() else page.resource_path.get_file().get_basename()

static func get_area(page: AdventurePage) -> AdventureArea: return page._area
static func get_events(page: AdventurePage) -> Array[AdventurePage]: return page._events

func get_link(from: AdventurePage, to: AdventurePage) -> Link:
	for link: Link in links: if link.from == from and link.to == to: return link
	return null

## A page linked both directly and through an event counts as linked directly
func _add_link(from: AdventurePage, to: AdventurePage, through_event: bool) -> void:
	if from == to: return
	var link: Link = get_link(from, to)
	if link == null: links.append(Link.new(from, to, through_event))
	elif not through_event: link.through_event = false

## Locations reached from [param host]'s events, also through (nested) events and pages without an area behind them
static func _get_event_targets(host: AdventurePage) -> Array[AdventurePage]:
	var hidden: Array[AdventurePage] = host._events.duplicate()
	var targets: Array[AdventurePage] = [ ]
	var index: int = 0
	while index < hidden.size():
		var page: AdventurePage = hidden[index]
		index += 1
		for event: AdventurePage in page._events: if not hidden.has(event): hidden.append(event)
		for target: AdventurePage in _get_targets(page._decisions):
			if target._area != null: targets.append(target)
			elif not hidden.has(target): hidden.append(target)
	return targets

## Every page reference a decision holds counts (success, failure, flee, draw ...), so new decision kinds need no change here.
## Read as properties, since decision scripts aren't @tool and are only placeholders in the editor.
static func _get_targets(decisions: Array[AdventureDecision]) -> Array[AdventurePage]:
	var targets: Array[AdventurePage] = [ ]
	for decision: AdventureDecision in decisions:
		if decision == null: continue
		for property: Dictionary in decision.get_property_list():
			if not property.usage & PROPERTY_USAGE_STORAGE: continue
			var value: Variant = decision.get(property.name)
			if not value is AdventurePageReference: continue
			var target: AdventurePage = (value as AdventurePageReference).get_adventure_page()
			if target != null: targets.append(target)
	return targets
