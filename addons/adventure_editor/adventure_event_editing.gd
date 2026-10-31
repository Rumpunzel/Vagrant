@tool
class_name AdventureEventEditing
extends RefCounted

## Event edits as data, apart from undo and saving in [AdventureEditor], so they can be tested.
## Pages behind an event live inside the event's file; a file can't store a cycle of its own resources.

## The path of the file [param resource] is stored in (a resource inside another file: that file's)
static func get_file_path(resource: Resource) -> String:
	return resource.resource_path.get_slice("::", 0)

## How a decision in the file at [param file_path] points at [param target]: the page itself in the same file, a transition to another file
static func make_reference(target: AdventurePage, file_path: String) -> AdventurePageReference:
	var target_path: String = get_file_path(target)
	if target_path.is_empty() or target_path == file_path: return target
	return AdventureTransition.leading_to(target)

## The file [param resource] is stored in: itself, or the file holding it; [param fallback] (else itself) while it is stored nowhere yet
static func get_file(resource: Resource, fallback: Resource = null) -> Resource:
	if resource.resource_path.is_empty(): return fallback if fallback != null else resource
	return load(get_file_path(resource)) if resource.resource_path.contains("::") else resource

## Whether [param page] is stored inside another file (or not stored yet), so it is lost once nothing in that file points at it
static func is_inside_file(page: AdventurePage) -> bool:
	return page.resource_path.is_empty() or page.resource_path.contains("::")

## Every [decision, property] pointing at [param target] directly, among what [param root] holds (its file's contents)
static func find_references_to(root: AdventurePage, target: AdventurePage) -> Array[Array]:
	var found: Array[Array] = [ ]
	for page: AdventurePage in root.get_held_pages():
		for decision: AdventureDecision in page.decisions:
			if decision == null: continue
			for outcome: AdventureDecision.Outcome in decision.get_outcomes():
				if decision.get_reference(outcome) == target: found.append([decision, outcome.reference_property])
	return found

## Whether dropping [param references] (pages they point at) loses a page stored inside [param root]'s file: nothing else there points at it
static func would_lose_page(root: AdventurePage, references: Array[AdventurePageReference]) -> bool:
	for link: AdventurePageReference in references:
		var page: AdventurePage = link as AdventurePage
		if page != null and is_inside_file(page) and find_references_to(root, page).size() <= references.count(link): return true
	return false

## Whether pointing from [param from] at [param target] closes a cycle: [param target] already reaches [param from] through pages (and events) held directly
static func would_loop(from: AdventurePage, target: AdventurePage) -> bool:
	return target.get_held_pages().has(from)

## Changes forgetting [param target] everywhere in [param roots] (files) and what they hold, each [resource, property, value, file]:
## plain decisions leading only there go, fight and save outcomes leading there go back, it is no event or option any more, and UID lists forget it
static func get_changes_forgetting(target: AdventurePage, roots: Array[AdventurePage]) -> Array[Array]:
	var changes: Array[Array] = [ ]
	var seen: Array[AdventurePage] = [ ]
	var target_uid: String = AdventureLayout.get_key(target) if not is_inside_file(target) else ""
	for root: AdventurePage in roots:
		for page: AdventurePage in root.get_held_pages():
			if seen.has(page) or page == target: continue
			seen.append(page)
			var file: Resource = load(get_file_path(page)) if not page.resource_path.is_empty() else root
			var kept: Array[AdventureDecision] = [ ]
			for decision: AdventureDecision in page.decisions:
				if decision != null and not decision is AdventureDiceDecision and _leads_to(decision.transition, target): continue
				kept.append(decision)
				if decision == null: continue
				for outcome: AdventureDecision.Outcome in decision.get_outcomes():
					if _leads_to(decision.get_reference(outcome), target): changes.append([decision, outcome.reference_property, null, file])
			if kept.size() != page.decisions.size(): changes.append([page, &"decisions", kept, file])
			if page is AdventureEventScenario and (page as AdventureEventScenario).events.has(target):
				var without: Array[AdventureEvent] = (page as AdventureEventScenario).events.duplicate()
				without.erase(target)
				changes.append([page, &"events", without, file])
			# Back-pointers by UID: where encounters could be, where events may show, a location's order
			for list: StringName in [&"places", &"only_at", &"order"]:
				if not list in page or target_uid.is_empty(): continue
				var paths: Array[String] = [ ]
				paths.assign(page.get(list) as Array)
				if not paths.has(target_uid): continue
				paths.erase(target_uid)
				changes.append([page, list, paths, file])
	return changes

## Changes listing [param events] on [param host], each [resource, property, value, file]: a scenario's options, or a location's own events
## (in its own scenario, made here if it has none, picking all that fit)
static func get_changes_listing(host: AdventurePage, events: Array[AdventureEvent]) -> Array[Array]:
	var file: Resource = get_file(host)
	var scenario: AdventureEventScenario = host as AdventureEventScenario
	var location: AdventureLocation = host as AdventureLocation
	if location != null: scenario = location.scenario
	if scenario != null: return [[scenario, &"events", events, file]]
	if location == null: return [ ]
	var own: AdventureEventScenario = _in_file(AdventureEventScenario.new()) as AdventureEventScenario
	own.pick = AdventureEventScenario.Pick.ALL
	own.events = events
	return [[location, &"scenario", own, file]]

## Changes taking [param area] off the pages in it
static func get_changes_forgetting_area(area: AdventureArea, pages: Array[AdventurePage]) -> Array[Array]:
	var changes: Array[Array] = [ ]
	for page: AdventurePage in pages: if page is AdventureLocation and (page as AdventureLocation).area == area: changes.append([page, &"area", null, page])
	return changes

static func _leads_to(link: AdventurePageReference, target: AdventurePage) -> bool:
	return link != null and link.load_page() == target

## Every event file in an [code]events[/code] folder under [param folder]
static func find_event_files(folder: String) -> Array[String]:
	var found: Array[String] = [ ]
	for sub_folder: String in DirAccess.get_directories_at(folder):
		var path: String = folder.path_join(sub_folder)
		if sub_folder == "events":
			for file: String in DirAccess.get_files_at(path):
				if file.get_extension() == "tres": found.append(path.path_join(file))
		found.append_array(find_event_files(path))
	return found

## A "↺ Host" or "↶ Previous location" link to be stored inside a file
static func make_special_reference(previous_location: bool) -> AdventurePageReference:
	var link: AdventurePageReference = AdventurePreviousLocationReference.new() if previous_location else AdventureHostReference.new()
	return _in_file(link) as AdventurePageReference

## A page to be stored inside a file
static func make_page() -> AdventurePage:
	return _in_file(AdventurePage.new()) as AdventurePage

static func make_choice() -> AdventureDecision:
	var choice: AdventureDecision = _in_file(AdventureDecision.new()) as AdventureDecision
	choice.description = "New choice."
	return choice

## Enemies are set in the Inspector
static func make_fight() -> AdventureFightDecision:
	var fight: AdventureFightDecision = _in_file(AdventureFightDecision.new()) as AdventureFightDecision
	fight.description = "Fight!"
	return fight

## Attribute and difficulty are set in the Inspector
static func make_save() -> AdventureSaveDecision:
	var save: AdventureSaveDecision = _in_file(AdventureSaveDecision.new()) as AdventureSaveDecision
	save.description = "New save."
	return save

static func make_event(title: String, scenario: bool) -> AdventureEvent:
	var event: AdventureEvent = AdventureEventScenario.new() if scenario else AdventureEvent.new()
	event.title = title
	return event

## In the [code]events[/code] folder next to [param host]'s file (its own folder, if it is in one already)
static func get_event_path(host: AdventurePage, title: String) -> String:
	var folder: String = get_file_path(host).get_base_dir()
	if folder.get_file() != "events": folder = folder.path_join("events")
	return folder.path_join(AdventureMapEditing.get_file_name(title))

## Every kind of consequence there is (scripts extending [AdventureConsequence] that can be made), by class name
static func get_consequence_types() -> Dictionary[String, Script]: return _get_types("AdventureConsequence")

## Every kind of condition there is, by class name
static func get_condition_types() -> Dictionary[String, Script]: return _get_types("AdventureCondition")

static func _get_types(base_name: String) -> Dictionary[String, Script]:
	var bases: Dictionary[String, String] = {}
	var paths: Dictionary[String, String] = {}
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		bases[entry["class"]] = entry["base"]
		paths[entry["class"]] = entry["path"]
	var types: Dictionary[String, Script] = {}
	for type_name: String in bases:
		var base: String = bases[type_name]
		while bases.has(base) and base != base_name: base = bases[base]
		if base != base_name: continue
		var script: Script = load(paths[type_name])
		if script.can_instantiate(): types[type_name] = script
	return types

## "AdventureStageConsequence" -> "Stage", "AdventureStageCondition" -> "Stage"
static func get_type_name(type_name: String) -> String:
	return type_name.trim_prefix("Adventure").trim_suffix("Consequence").trim_suffix("Condition").capitalize()

static func make_condition(type: Script) -> AdventureCondition:
	return _in_file(type.new() as Resource) as AdventureCondition

## "[param track] is [param stage]" of the event's own encounter
static func make_stage_condition(track: String, stage: String) -> AdventureStageCondition:
	var condition: AdventureStageCondition = _in_file(AdventureStageCondition.new()) as AdventureStageCondition
	condition.track = track
	condition.stages = [stage] as Array[String]
	return condition

## "[param track] → [param stage]" of the encounter of the event one is in
static func make_stage_consequence(track: String, stage: String) -> AdventureStageConsequence:
	var consequence: AdventureStageConsequence = _in_file(AdventureStageConsequence.new()) as AdventureStageConsequence
	consequence.track = track
	consequence.stage = stage
	return consequence

## A stage track to be stored inside its encounter's or location's file, without stages yet
static func make_track(track_name: String) -> AdventureStageTrack:
	var track: AdventureStageTrack = _in_file(AdventureStageTrack.new()) as AdventureStageTrack
	track.name = track_name
	return track

## In its own folder under [code]encounters[/code] next to the adventure
static func get_encounter_path(adventure: Adventure, title: String) -> String:
	var file_name: String = AdventureMapEditing.get_file_name(title)
	return adventure.resource_path.get_base_dir().path_join("encounters").path_join(file_name.get_basename()).path_join(file_name)

## A new encounter that could be at [param location], with its files (path -> resource, in saving order: what the encounter points at first).
## An NPC gets a Storyline (Unmet / Met); with [param profile] a monster gets a State track (Lurking / Beaten / Dead) and an ambush while it
## lurks, whose won fight beats it and goes back to where it happened.
static func make_encounter_files(adventure: Adventure, title: String, location: AdventureLocation, profile: MonsterProfile = null) -> Dictionary[String, Resource]:
	var files: Dictionary[String, Resource] = {}
	var path: String = get_encounter_path(adventure, title)
	var encounter: AdventureEncounter = AdventureEncounter.new()
	encounter.title = title
	encounter.profile = profile
	encounter.places = [AdventureLayout.get_key(location)] as Array[String]
	var track: AdventureStageTrack = make_track("State" if profile != null else "Storyline")
	var stages: Array[String] = ["Unmet", "Met"]
	if profile != null: stages = ["Lurking", "Beaten", "Dead"]
	track.stages = stages
	encounter.tracks = [track] as Array[AdventureStageTrack]
	if profile != null:
		var ambush: AdventureEvent = AdventureEvent.new()
		ambush.title = "%s Ambush" % title
		ambush.exclusivity = AdventureEvent.Exclusivity.EXCLUDE_BASE | AdventureEvent.Exclusivity.EXCLUDE_BELOW | AdventureEvent.Exclusivity.EXCLUDE_ABOVE
		ambush.conditions = [make_stage_condition("State", "Lurking")] as Array[AdventureCondition]
		var fight: AdventureFightDecision = make_fight()
		fight.consequences = [make_stage_consequence("State", "Beaten")] as Array[AdventureConsequence]
		fight.transition = make_special_reference(false)
		ambush.decisions = [fight] as Array[AdventureDecision]
		files[path.get_base_dir().path_join(path.get_file().get_basename() + "_ambush.tres")] = ambush
		encounter.events = [ambush] as Array[AdventureEvent]
	files[path] = encounter
	return files

static func make_consequence(type: Script) -> AdventureConsequence:
	return _in_file(type.new() as Resource) as AdventureConsequence


## Gives [param resource] its ID inside the file now, so the layout can key it before it is saved
static func _in_file(resource: Resource) -> Resource:
	resource.resource_scene_unique_id = Resource.generate_scene_unique_id()
	return resource
