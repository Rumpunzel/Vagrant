@tool
class_name AdventureEventGraph
extends RefCounted

## What happens inside one event: the pages behind it (reached through its decisions and the outcomes of its fights and saves; nested events stay cards)
## and the locations it leads out to

## Where a decision (or a check's outcome) leads
class Outlet:
	var label: String
	var decision: AdventureDecision
	## The decision's property holding the reference
	var property: StringName = &"transition"
	## None: goes back, to the host or to a check
	var target: AdventurePage
	## "↺ Host": back to the page the event is on
	var to_host: bool
	## "↶ Previous location": back to before the host
	var to_previous: bool
	## A fight or save, whose outcomes lead on
	var to_check: bool
	var consequences: Array[AdventureConsequence]
	## The decision's property holding [member consequences]; empty: this outcome has none
	var consequences_property: StringName

	## How many pages going back goes
	func get_back_steps() -> int: return decision.back_steps

	func goes_back() -> bool: return target == null and not to_host and not to_previous and not to_check

var event: AdventurePage
## The event first, then the pages behind it
var pages: Array[AdventurePage] = [ ]
## Locations (pages with an area) it leads to
var exits: Array[AdventurePage] = [ ]
## Some outlet leads back to the host
var leads_to_host: bool = false
## Steps from the event (pages, exits), for placing nodes
var depths: Dictionary[AdventurePage, int] = {}

func _init(root_event: AdventurePage) -> void:
	event = root_event
	pages.append(root_event)
	depths[root_event] = 0
	var index: int = 0
	while index < pages.size():
		var page: AdventurePage = pages[index]
		index += 1
		for outlet: Outlet in get_ports(page): _reach(outlet, depths[page] + 1)

## One per decision of [param page]; fights and saves ([member Outlet.to_check]) lead on through their outcomes
static func get_outlets(page: AdventurePage) -> Array[Outlet]:
	var outlets: Array[Outlet] = [ ]
	for decision: AdventureDecision in page.decisions:
		if decision == null: continue
		var outlet: Outlet = Outlet.new()
		outlet.label = decision.description.get_slice("\n", 0)
		outlet.decision = decision
		if decision is AdventureDiceDecision: outlet.to_check = true
		else:
			_point(outlet, decision.transition)
			outlet.consequences = decision.consequences
			outlet.consequences_property = &"consequences"
		outlets.append(outlet)
	return outlets

## What a page's output ports lead to, in order: a plain decision's target, then a fight's or save's outcomes
static func get_ports(page: AdventurePage) -> Array[Outlet]:
	var ports: Array[Outlet] = [ ]
	for outlet: Outlet in get_outlets(page):
		if outlet.to_check: ports.append_array(get_outcomes(outlet.decision))
		else: ports.append(outlet)
	return ports

## The outcomes of a fight or save ([method AdventureDecision.get_outcomes])
static func get_outcomes(check: AdventureDecision) -> Array[Outlet]:
	var outcomes: Array[Outlet] = [ ]
	for outcome: AdventureDecision.Outcome in check.get_outcomes():
		var outlet: Outlet = Outlet.new()
		outlet.label = outcome.name
		outlet.decision = check
		outlet.property = outcome.reference_property
		outlet.consequences_property = outcome.consequences_property
		outlet.consequences = check.get_consequences_of(outcome)
		_point(outlet, check.get_reference(outcome))
		outcomes.append(outlet)
	return outcomes

## What a check is about: "Fight: Lurker", "Save: Blood 7"
static func describe_check(check: AdventureDecision) -> String:
	if check is AdventureFightDecision:
		var names: Array[String] = [ ]
		for enemy: MonsterProfile in (check as AdventureFightDecision).enemies: if enemy != null: names.append(enemy.name)
		return "Fight: %s" % ", ".join(names)
	if check is AdventureSaveDecision:
		var save: AdventureSaveDecision = check as AdventureSaveDecision
		return "Save: %s %d" % [save.attribute.descriptor if save.attribute != null else "?", save.difficulty]
	return "Check"

static func describe_consequences(consequences: Array[AdventureConsequence]) -> String:
	var texts: Array[String] = [ ]
	for consequence: AdventureConsequence in consequences: if consequence != null: texts.append(consequence.describe())
	return ", ".join(texts)

static func _point(outlet: Outlet, link: AdventurePageReference) -> void:
	if link == null: return
	outlet.to_host = link is AdventureHostReference
	outlet.to_previous = link is AdventurePreviousLocationReference
	outlet.target = link.get_adventure_page()

func _reach(outlet: Outlet, depth: int) -> void:
	if outlet.to_host: leads_to_host = true
	if outlet.target == null or depths.has(outlet.target): return
	depths[outlet.target] = depth
	if outlet.target.area != null: exits.append(outlet.target)
	else: pages.append(outlet.target)
