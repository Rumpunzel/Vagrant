@tool
class_name AdventureTooltips
extends RefCounted

## What the adventure editor's rich tooltips ([AdventureTooltipTrigger]) say about events, scenarios, encounters, pages and decisions of [member graph]:
## at a glance what they are, when and where they show, and links to what they name ([method describe_link] shows those, [method open_link]
## opens them)

## A link was clicked: show [param resource] (an event opens on its screen, a page on the map)
signal opened(resource: Resource)

const TEXT_LENGTH: int = 180
const DIM: Color = Color(1, 1, 1, 0.6)
const LINK: Color = Color(0.55, 0.75, 1.0)
const WARNING: Color = Color(1.0, 0.7, 0.35)
const THUMBNAIL_WIDTH: int = 200

var graph: AdventureGraph
## Shown on the tooltips of what they are about
var problems: Array[AdventureProblems.Problem] = [ ]

func _init(of: AdventureGraph) -> void:
	graph = of

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
	return ""

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
	var layering: Array[String] = [ ]
	var names: Array[String] = ["adds to the page", "replaces the location's", "only its own"]
	if event.text_layering != AdventureEvent.Layering.ADDS: layering.append("text: " + names[event.text_layering])
	if event.decisions_layering != AdventureEvent.Layering.ADDS: layering.append("decisions: " + names[event.decisions_layering])
	if event.no_rest: layering.append("no rest here")
	if not layering.is_empty(): lines.append("[b]On the page:[/b] " + "; ".join(layering))
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
	var events: Array[String] = [ ]
	for event: AdventureEvent in AdventureGraph.get_listed_on(page): events.append(_link(event))
	if location != null: for encounter: AdventureEncounter in graph.get_encounters_at(location): events.append(_link(encounter))
	if not events.is_empty(): lines.append("[b]Events:[/b] " + ", ".join(events))
	lines.append_array(_describe_text_and_decisions(page))
	return "\n".join(lines)

func _describe_text_and_decisions(page: AdventurePage) -> Array[String]:
	var lines: Array[String] = [ ]
	var text: String = page.description.strip_edges()
	if not text.is_empty(): lines.append("[i]%s[/i]" % _escape(text if text.length() <= TEXT_LENGTH else text.left(TEXT_LENGTH).strip_edges() + "…"))
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
