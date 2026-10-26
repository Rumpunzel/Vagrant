@tool
class_name AdventureEventGraph
extends RefCounted

## What happens inside one event: the pages behind it (reached through its decisions; nested events stay cards), its checks (fights, saves)
## and the locations it leads out to

## Outcomes of a check by kind: [reference property, label, consequences property]; a fixed order, so the graph reads the same for every check
const FIGHT_OUTCOMES: Array[Array] = [[&"transition", "Won", &"consequences"], [&"failure_transition", "Lost", &"failure_consequences"], [&"flee_transition", "Fled", &""], [&"draw_transition", "Draw", &""]]
const DICE_OUTCOMES: Array[Array] = [[&"transition", "Success", &"consequences"], [&"failure_transition", "Failure", &"failure_consequences"]]

## Where a decision (or a check's outcome) leads
class Outlet:
	var label: String
	var decision: AdventureDecision
	## None: goes back, to the host or to a check
	var target: AdventurePage
	## "↺ Host": back to the page the event is on
	var to_host: bool
	## A page's row for a fight or save: leads to the check's node, whose outcomes lead on
	var to_check: bool
	var consequences: Array[AdventureConsequence]

	func goes_back() -> bool: return target == null and not to_host and not to_check

var event: AdventurePage
## The event first, then the pages behind it
var pages: Array[AdventurePage] = [ ]
## Fights and saves of the pages, in order
var checks: Array[AdventureDecision] = [ ]
## Locations (pages with an area) it leads to
var exits: Array[AdventurePage] = [ ]
## Some outlet leads back to the host
var leads_to_host: bool = false
## Steps from the event (pages, checks, exits), for placing nodes
var depths: Dictionary[Resource, int] = {}

func _init(root_event: AdventurePage) -> void:
	event = root_event
	pages.append(root_event)
	depths[root_event] = 0
	var index: int = 0
	while index < pages.size():
		var page: AdventurePage = pages[index]
		index += 1
		for outlet: Outlet in get_outlets(page):
			if outlet.to_check:
				checks.append(outlet.decision)
				depths[outlet.decision] = depths[page] + 1
				for outcome: Outlet in get_outcomes(outlet.decision): _reach(outcome, depths[page] + 2)
			else: _reach(outlet, depths[page] + 1)

## One row per decision of [param page]; fights and saves lead to their check
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
		outlets.append(outlet)
	return outlets

## The outcomes of a fight or save, in a fixed order per kind; other page references of new kinds of checks follow
static func get_outcomes(check: AdventureDecision) -> Array[Outlet]:
	var specs: Array[Array] = FIGHT_OUTCOMES if check is AdventureFightDecision else DICE_OUTCOMES
	var outcomes: Array[Outlet] = [ ]
	var known: Array[StringName] = [ ]
	for spec: Array in specs:
		known.append(spec[0])
		var outcome: Outlet = Outlet.new()
		outcome.label = spec[1]
		outcome.decision = check
		_point(outcome, check.get(spec[0]) as AdventurePageReference)
		if spec[2] != &"": outcome.consequences.assign(check.get(spec[2]))
		outcomes.append(outcome)
	for property: StringName in AdventureGraph.get_references(check):
		if known.has(property): continue
		var extra: Outlet = Outlet.new()
		extra.label = String(property).trim_suffix("_transition").capitalize()
		extra.decision = check
		_point(extra, AdventureGraph.get_references(check)[property])
		outcomes.append(extra)
	return outcomes

## What a check is about: "Fight: Lurker", "Save: Blood 7"
static func describe_check(check: AdventureDecision) -> String:
	if check is AdventureFightDecision:
		var names: Array[String] = [ ]
		for enemy: MonsterProfile in check.get(&"enemies"): if enemy != null: names.append(enemy.name)
		return "Fight: %s" % ", ".join(names)
	if check is AdventureSaveDecision:
		var attribute: CharacterAttribute = check.get(&"attribute")
		return "Save: %s %d" % [attribute.descriptor if attribute != null else "?", check.get(&"difficulty")]
	return "Check"

static func describe_consequences(consequences: Array[AdventureConsequence]) -> String:
	var texts: Array[String] = [ ]
	for consequence: AdventureConsequence in consequences: if consequence != null: texts.append(consequence.describe())
	return ", ".join(texts)

static func _point(outlet: Outlet, reference: AdventurePageReference) -> void:
	if reference == null: return
	outlet.to_host = reference is AdventureHostReference
	outlet.target = reference.get_adventure_page()

func _reach(outlet: Outlet, depth: int) -> void:
	if outlet.to_host: leads_to_host = true
	if outlet.target == null or depths.has(outlet.target): return
	depths[outlet.target] = depth
	if outlet.target.area != null: exits.append(outlet.target)
	else: pages.append(outlet.target)
