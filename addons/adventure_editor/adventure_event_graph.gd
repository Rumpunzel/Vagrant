@tool
class_name AdventureEventGraph
extends RefCounted

## What happens inside one event: the pages behind it (reached through its decisions; nested events stay cards) and the locations it leads out to

class Outlet:
	var label: String
	## None: goes back, or to the host
	var target: AdventurePage
	## "↺ Host": back to the page the event is on
	var to_host: bool

	func _init(outlet_label: String, outlet_target: AdventurePage, is_to_host: bool = false) -> void:
		label = outlet_label
		target = outlet_target
		to_host = is_to_host

var event: AdventurePage
## The event first, then the pages behind it
var pages: Array[AdventurePage] = [ ]
## Locations (pages with an area) it leads to
var exits: Array[AdventurePage] = [ ]
## Some outlet leads back to the host
var leads_to_host: bool = false
## Steps from the event, for placing nodes
var depths: Dictionary[AdventurePage, int] = {}

func _init(root_event: AdventurePage) -> void:
	event = root_event
	pages.append(root_event)
	depths[root_event] = 0
	var index: int = 0
	while index < pages.size():
		var page: AdventurePage = pages[index]
		index += 1
		for outlet: Outlet in get_outlets(page):
			if outlet.to_host: leads_to_host = true
			if outlet.target == null or depths.has(outlet.target): continue
			depths[outlet.target] = depths[page] + 1
			if outlet.target.area != null: exits.append(outlet.target)
			else: pages.append(outlet.target)

## One per decision outcome: the decision's text for its transition, then its other page references (failure, flee, draw ...)
static func get_outlets(page: AdventurePage) -> Array[Outlet]:
	var outlets: Array[Outlet] = [ ]
	for decision: AdventureDecision in page.decisions:
		if decision == null: continue
		var text: String = decision.description.get_slice("\n", 0)
		var references: Dictionary[StringName, AdventurePageReference] = AdventureGraph.get_references(decision)
		if not references.has(&"transition"): outlets.append(Outlet.new("%s (back)" % text, null))
		for property: StringName in references:
			var label: String = text if property == &"transition" else "↳ %s" % String(property).trim_suffix("_transition").capitalize()
			var reference: AdventurePageReference = references[property]
			outlets.append(Outlet.new(label, reference.get_adventure_page(), reference is AdventureHostReference))
	return outlets
