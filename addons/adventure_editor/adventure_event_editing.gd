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
	for reference: AdventurePageReference in references:
		var page: AdventurePage = reference as AdventurePage
		if page != null and is_inside_file(page) and find_references_to(root, page).size() <= references.count(reference): return true
	return false

## Whether pointing from [param from] at [param target] closes a cycle: [param target] already reaches [param from] through pages (and events) held directly
static func would_loop(from: AdventurePage, target: AdventurePage) -> bool:
	return target.get_held_pages().has(from)

## Changes forgetting [param target] everywhere in [param roots] (files) and what they hold, each [resource, property, value, file]:
## plain decisions leading only there go, fight and save outcomes leading there go back, and it is no event, option or nearby event any more
static func get_changes_forgetting(target: AdventurePage, roots: Array[AdventurePage]) -> Array[Array]:
	var changes: Array[Array] = [ ]
	var seen: Array[AdventurePage] = [ ]
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
			for list: StringName in [&"events", &"nearby_events"]:
				var listed: Array[AdventurePage] = page.get(list)
				if not listed.has(target): continue
				var without: Array[AdventurePage] = listed.duplicate()
				without.erase(target)
				changes.append([page, list, without, file])
	return changes

## Changes taking [param area] off the pages in it
static func get_changes_forgetting_area(area: AdventureArea, pages: Array[AdventurePage]) -> Array[Array]:
	var changes: Array[Array] = [ ]
	for page: AdventurePage in pages: if page.area == area: changes.append([page, &"area", null, page])
	return changes

static func _leads_to(reference: AdventurePageReference, target: AdventurePage) -> bool:
	return reference != null and reference.load_page() == target

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
	var reference: AdventurePageReference = AdventurePreviousLocationReference.new() if previous_location else AdventureHostReference.new()
	return _in_file(reference) as AdventurePageReference

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

static func make_event(title: String, scenario: bool) -> AdventurePage:
	var event: AdventurePage = AdventureEventScenario.new() if scenario else AdventurePage.new()
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

## "AdventureKillMonsterConsequence" -> "Kill Monster", "AdventureMonsterCondition" -> "Monster"
static func get_type_name(type_name: String) -> String:
	return type_name.trim_prefix("Adventure").trim_suffix("Consequence").trim_suffix("Condition").capitalize()

static func make_condition(type: Script) -> AdventureCondition:
	return _in_file(type.new() as Resource) as AdventureCondition

## A condition on [param owner] about the [param index]th [param monster] spawned by [param spawning]'s fight; none if [param owner] can't point at it
## (it would loop: [param spawning] holds [param owner] in the same file)
static func make_monster_condition(state: AdventureMonsterCondition.State, monster: MonsterProfile, index: int, spawning: AdventurePage, owner: AdventurePage) -> AdventureMonsterCondition:
	var reference: AdventureMonsterReference = _in_file(AdventureMonsterReference.new()) as AdventureMonsterReference
	reference.monster = monster
	reference.index = index
	if spawning != owner:
		if get_file_path(spawning) == get_file_path(owner) and would_loop(owner, spawning): return null
		reference.spawned_by = make_reference(spawning, get_file_path(owner))
	var condition: AdventureMonsterCondition = _in_file(AdventureMonsterCondition.new()) as AdventureMonsterCondition
	condition.monster = reference
	condition.state = state
	return condition

static func make_consequence(type: Script) -> AdventureConsequence:
	return _in_file(type.new() as Resource) as AdventureConsequence


## Gives [param resource] its ID inside the file now, so the layout can key it before it is saved
static func _in_file(resource: Resource) -> Resource:
	resource.resource_scene_unique_id = Resource.generate_scene_unique_id()
	return resource
