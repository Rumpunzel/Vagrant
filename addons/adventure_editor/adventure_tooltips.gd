@tool
class_name AdventureTooltips
extends RefCounted

## What the adventure editor's rich tooltips ([AdventureTooltipTrigger]) say about events, scenarios, encounters, pages and decisions of [member graph]:
## at a glance what they are, when and where they show, and links to what they name ([method describe_link] shows those, [method open_link]
## opens them)

## A link was clicked: show [param resource] (an event opens on its screen, a page on the map)
signal opened(resource: Resource)

## One stage of a subject's track, for a tooltip about it ([method get_stage])
class StageOf extends Resource:
	var subject: Resource
	var track: String
	var stage: String

const TEXT_LENGTH: int = 180
const DIM: Color = Color(1, 1, 1, 0.6)
const LINK: Color = Color(0.55, 0.75, 1.0)
const WARNING: Color = Color(1.0, 0.7, 0.35)
const THUMBNAIL_WIDTH: int = 200

var graph: AdventureGraph
## Shown on the tooltips of what they are about
var problems: Array[AdventureProblems.Problem] = [ ]
## Who sets and needs each stage
var stages: AdventureStageIndex

func _init(of: AdventureGraph) -> void:
	graph = of
	var events: Array[AdventureEvent] = [ ]
	events.assign(graph.event_hosts.keys())
	stages = AdventureStageIndex.new(graph, events)

## A tooltip subject for [param stage] of [param subject]'s [param track]
static func get_stage(subject: Resource, track: String, stage: String) -> StageOf:
	var about: StageOf = StageOf.new()
	about.subject = subject
	about.track = track
	about.stage = stage
	return about

## A rich tooltip about [param about] on [param control], instead of its plain one
func attach(control: Control, about: Resource) -> AdventureTooltipTrigger:
	control.tooltip_text = ""
	return _attach(control, about)

## A tooltip for each link of [param label]
func attach_links(label: RichTextLabel) -> AdventureTooltipTrigger: return _attach(label, null)

func _attach(control: Control, about: Resource) -> AdventureTooltipTrigger:
	var trigger: AdventureTooltipTrigger = AdventureTooltipTrigger.new()
	trigger.trigger_node = control
	trigger.subject = about
	trigger.tooltips = self
	control.add_child(trigger)
	return trigger

func describe(resource: Resource) -> String:
	if resource is AdventureEncounter: return _describe_encounter(resource as AdventureEncounter)
	if resource is AdventureEventScenario: return _describe_scenario(resource as AdventureEventScenario)
	if resource is AdventureEvent: return _describe_event(resource as AdventureEvent)
	if resource is AdventurePage: return _describe_page(resource as AdventurePage)
	if resource is AdventureDecision: return _describe_decision(resource as AdventureDecision)
	return _describe_stages(resource)

## A stage, or the stages a stage condition needs or a stage effect sets; anything else: nothing
func _describe_stages(resource: Resource) -> String:
	if resource is AdventureStageCondition: return _describe_stage_condition(resource as AdventureStageCondition)
	if resource is AdventureStageConsequence: return _describe_stage_effect(resource as AdventureStageConsequence)
	var about: StageOf = resource as StageOf
	return "\n".join(_describe_stage(about.subject, about.track, about.stage)) if about != null else ""

## A link's meta is the instance ID of what it names
func describe_link(meta: Variant) -> String: return describe(_find(meta))

func open_link(meta: Variant) -> void:
	var resource: Resource = _find(meta)
	if resource == null: return
	TooltipManager.force_close_stack()
	opened.emit(resource)

static func _find(meta: Variant) -> Resource:
	var id: int = str(meta).to_int()
	return instance_from_id(id) as Resource if id != 0 and is_instance_id_valid(id) else null

func _describe_encounter(encounter: AdventureEncounter) -> String:
	var kind: String = "monster" if encounter.profile is MonsterProfile else "someone"
	if encounter.profile != null and not encounter.profile.name.is_empty(): kind += ": " + _escape(encounter.profile.name)
	var lines: Array[String] = [_heading(encounter, "encounter (%s)" % kind)]
	var places: Array[String] = [ ]
	for location: AdventureLocation in graph.get_encounter_locations(encounter): places.append(_link(location))
	lines.append("[b]Could be at:[/b] " + (", ".join(places) if not places.is_empty() else _dim("nowhere yet")))
	for track: AdventureStageTrack in encounter.tracks:
		if track != null: lines.append("[b]%s:[/b] %s" % [_escape(track.name), _escape(" → ".join(track.stages))])
	lines.append_array(_describe_options(encounter))
	return "\n".join(lines)

func _describe_scenario(scenario: AdventureEventScenario) -> String:
	var lines: Array[String] = [_heading(scenario, "scenario: shows %s" % ("the first that fits" if scenario.pick == AdventureEventScenario.Pick.FIRST else "every one that fits"))]
	lines.append_array(_get_owners(scenario))
	lines.append_array(_describe_options(scenario))
	return "\n".join(lines)

func _describe_options(scenario: AdventureEventScenario) -> Array[String]:
	var lines: Array[String] = ["[b]Events:[/b]"]
	for option: AdventureEvent in scenario.events:
		if option == null: continue
		var needs: String = _describe_conditions(option.conditions)
		lines.append("• %s %s" % [_link(option), _dim("when " + _escape(needs)) if not needs.is_empty() else _dim("always")])
	if lines.size() == 1: lines.append(_dim("none"))
	return lines

func _describe_event(event: AdventureEvent) -> String:
	var lines: Array[String] = [_heading(event, "event")]
	lines.append_array(_get_owners(event))
	lines.append_array(_get_problems(event))
	var needs: String = _describe_conditions(event.conditions)
	lines.append("[b]When:[/b] " + (_escape(needs) if not needs.is_empty() else "always"))
	var layering: String = _describe_layering(event)
	if not layering.is_empty(): lines.append("[b]On the page:[/b] " + layering)
	lines.append_array(_describe_text_and_decisions(event))
	return "\n".join(lines)

func _describe_page(page: AdventurePage) -> String:
	var location: AdventureLocation = page as AdventureLocation
	var kind: String = "location" if location != null else "page"
	if location != null and location.area != null: kind += " in " + _escape(location.area.name)
	var lines: Array[String] = [_heading(page, kind)]
	var background: Texture2D = page.background if page.background != null else page.get_area_background()
	if background != null and not background.resource_path.is_empty(): lines.append("[img=%d]%s[/img]" % [THUMBNAIL_WIDTH, background.resource_path])
	if graph.unreachable.has(page): lines.append(_colored("Not reached from the starting page", WARNING))
	lines.append_array(_get_problems(page))
	if location != null: lines.append_array(_describe_reading(location))
	else: lines.append_array(_describe_text_and_decisions(page))
	return "\n".join(lines)

## How [param location]'s page reads, top to bottom: the area's text (coming from another area), its own, then what can show there in its
## order, each with when and how it changes the page; then its exits
func _describe_reading(location: AdventureLocation) -> Array[String]:
	var lines: Array[String] = ["[b]It reads:[/b]"]
	var area: AdventureArea = location.area
	if area != null and not (area.description + area.first_description).strip_edges().is_empty():
		lines.append("• %s %s" % [_dim("the area's text, coming from another area:"), _shorten(area.description if not area.description.is_empty() else area.first_description)])
		if not area.first_description.is_empty() and not area.description.is_empty(): lines.append("   %s %s" % [_dim("the first time:"), _shorten(area.first_description)])
	if not location.description.strip_edges().is_empty(): lines.append("• %s %s" % [_dim("its text:"), _shorten(location.description)])
	if not location.first_description.is_empty(): lines.append("   %s %s" % [_dim("the first visit:"), _shorten(location.first_description)])
	var encounters: Array[AdventureEncounter] = [ ]
	if graph.adventure != null: for encounter: AdventureEncounter in graph.adventure.encounters: if encounter != null: encounters.append(encounter)
	var overview: AdventureLocationOverview = AdventureLocationOverview.new(location, encounters, graph.pages)
	for section: AdventureLocationOverview.Section in overview.sections:
		if section.events.is_empty(): continue
		lines.append("• %s %s" % [_link(section.encounter) if section.encounter != null else _dim("its own events"), _dim(section.reason) if section.encounter != null else ""])
		for event: AdventureEvent in section.events:
			var needs: String = _describe_conditions(event.conditions)
			var layering: String = _describe_layering(event)
			lines.append("   %s %s%s" % [_link(event), _dim("when " + _escape(needs)) if not needs.is_empty() else _dim("always"), "  " + layering if not layering.is_empty() else ""])
	var exits: Array[String] = _describe_decisions(location)
	if not exits.is_empty():
		lines.append("[b]Exits:[/b]")
		lines.append_array(exits)
	return lines

## How [param event] changes the page it is on; empty: it only adds to it
static func _describe_layering(event: AdventureEvent) -> String:
	var names: Array[String] = ["adds to the page", "replaces the location's", "only its own"]
	var parts: Array[String] = [ ]
	if event.text_layering != AdventureEvent.Layering.ADDS: parts.append("text: " + names[event.text_layering])
	if event.decisions_layering != AdventureEvent.Layering.ADDS: parts.append("decisions: " + names[event.decisions_layering])
	if event.no_rest: parts.append("no rest here")
	return _colored("; ".join(parts), WARNING) if not parts.is_empty() else ""

static func _shorten(text: String) -> String:
	var stripped: String = text.strip_edges()
	return "[i]%s[/i]" % _escape(stripped if stripped.length() <= TEXT_LENGTH else stripped.left(TEXT_LENGTH).strip_edges() + "…")

func _describe_text_and_decisions(page: AdventurePage) -> Array[String]:
	var lines: Array[String] = [ ]
	if not page.description.strip_edges().is_empty(): lines.append(_shorten(page.description))
	lines.append_array(_describe_decisions(page))
	return lines

func _describe_decisions(page: AdventurePage) -> Array[String]:
	var lines: Array[String] = [ ]
	for decision: AdventureDecision in page.decisions:
		if decision == null: continue
		var targets: Array[String] = [ ]
		for reference: AdventurePageReference in decision.get_page_references():
			var target: AdventurePage = reference.get_adventure_page()
			targets.append(_dim("back") if target == null else _link_or_name(target))
		lines.append("• %s%s" % [_escape(decision.description.get_slice("\n", 0)), " → " + ", ".join(targets) if not targets.is_empty() else ""])
	return lines

func _describe_decision(decision: AdventureDecision) -> String:
	var kind: String = AdventureEventGraph.describe_check(decision) if decision is AdventureDiceDecision else "decision"
	var lines: Array[String] = ["[b]%s[/b]  %s" % [_escape(decision.description.get_slice("\n", 0)), _dim(_escape(kind))]]
	if not decision.first_description.is_empty(): lines.append("[b]The first time:[/b] " + _escape(decision.first_description))
	for outcome: AdventureEventGraph.Outlet in AdventureEventGraph.get_outcomes(decision):
		var target: String = _dim("back")
		if outcome.to_host: target = _dim("↺ Host")
		elif outcome.to_previous: target = _dim("↶ Previous location")
		elif outcome.target != null: target = _link_or_name(outcome.target)
		var effects: String = AdventureEventGraph.describe_consequences(outcome.consequences)
		var label: String = "[b]%s:[/b] " % outcome.label if not outcome.label.is_empty() else ""
		lines.append("• %s→ %s%s" % [label, target, "  " + _dim(_escape(effects)) if not effects.is_empty() else ""])
	return "\n".join(lines)

func _describe_stage_condition(condition: AdventureStageCondition) -> String:
	var lines: Array[String] = ["[b]%s[/b]  %s" % [_escape(_describe_conditions([condition] as Array[AdventureCondition])), _dim("condition")]]
	for subject: Resource in stages.get_subjects(condition):
		for stage: String in condition.stages: lines.append_array(_describe_stage(subject, condition.track, stage))
	return "\n".join(lines)

func _describe_stage_effect(effect: AdventureStageConsequence) -> String:
	var lines: Array[String] = ["[b]%s[/b]  %s" % [_escape(effect.describe()), _dim("effect")]]
	for subject: Resource in stages.get_subjects(effect): lines.append_array(_describe_stage(subject, effect.track, effect.stage))
	return "\n".join(lines)

## Where [param subject] gets into [param stage] and what waits for it there
func _describe_stage(subject: Resource, track: String, stage: String) -> Array[String]:
	var whose: String = _link(subject as AdventurePage) if subject is AdventurePage else _escape(str(subject))
	var lines: Array[String] = ["%s: %s is [b]%s[/b]%s" % [whose, _escape(track), _escape(stage), "  " + _dim("(its start)") if AdventureStageIndex.is_start(subject, track, stage) else ""]]
	var setters: Array[String] = [ ]
	for setter: AdventureStageIndex.Setter in stages.get_setters(subject, track, stage):
		var where: AdventurePage = setter.event if setter.event != null else setter.page
		setters.append("• \"%s\" %s %s" % [_escape(setter.decision.description.get_slice("\n", 0)), _dim("in"), _link(where)])
	lines.append("[b]Set by:[/b]" + (" " + _dim("nothing") if setters.is_empty() else ""))
	lines.append_array(setters)
	var needers: Array[String] = [ ]
	for event: AdventureEvent in stages.get_needers(subject, track, stage): needers.append(_link(event))
	lines.append("[b]Needed by:[/b] " + (", ".join(needers) if not needers.is_empty() else _dim("nothing")))
	return lines

func _get_problems(page: AdventurePage) -> Array[String]:
	var lines: Array[String] = [ ]
	for problem: AdventureProblems.Problem in problems: if problem.page == page: lines.append(_colored("⚠ " + _escape(problem.text), WARNING))
	return lines

static func _describe_conditions(conditions: Array[AdventureCondition]) -> String:
	return AdventureEventGraph.describe_conditions(conditions).replace("its own: ", "")

## The scenarios and encounters [param event] is an option of, and the locations listing it
func _get_owners(event: AdventureEvent) -> Array[String]:
	var owners: Array[String] = [ ]
	var at: Array[String] = [ ]
	for host: AdventurePage in graph.get_hosts(event):
		if host is AdventureEventScenario and not AdventureEventEditing.is_inside_file(host): owners.append(_link(host))
		elif host is AdventureLocation: at.append(_link(host))
	var lines: Array[String] = [ ]
	if not owners.is_empty(): lines.append("[b]Of:[/b] " + ", ".join(owners))
	if not at.is_empty(): lines.append("[b]Listed at:[/b] " + ", ".join(at))
	return lines

func _heading(resource: AdventurePage, kind: String) -> String:
	return "[b]%s[/b]  %s" % [_escape(AdventureGraph.get_title(resource)), _dim(kind)]

## Pages inside an event's file have nothing of their own to open
static func _link_or_name(page: AdventurePage) -> String:
	if page.resource_path.contains("::") and not page is AdventureEvent: return _dim(_escape(AdventureGraph.get_title(page)))
	return _link(page)

static func _link(page: AdventurePage) -> String:
	return "[url=%d][color=#%s]%s[/color][/url]" % [page.get_instance_id(), LINK.to_html(false), _escape(AdventureGraph.get_title(page))]

static func _dim(text: String) -> String: return _colored(text, DIM)

static func _colored(text: String, color: Color) -> String: return "[color=#%s]%s[/color]" % [color.to_html(), text]

static func _escape(text: String) -> String: return text.replace("[", "[lb]")
