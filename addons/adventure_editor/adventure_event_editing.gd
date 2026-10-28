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
	for page: AdventurePage in _get_held(root):
		for decision: AdventureDecision in page.decisions:
			if decision == null: continue
			var references: Dictionary[StringName, AdventurePageReference] = AdventureGraph.get_references(decision)
			for property: StringName in references:
				if references[property] == target: found.append([decision, property])
	return found

## Whether dropping [param references] (pages they point at) loses a page stored inside [param root]'s file: nothing else there points at it
static func would_lose_page(root: AdventurePage, references: Array[AdventurePageReference]) -> bool:
	for reference: AdventurePageReference in references:
		var page: AdventurePage = reference as AdventurePage
		if page != null and is_inside_file(page) and find_references_to(root, page).size() <= references.count(reference): return true
	return false

## Whether pointing from [param from] at [param target] closes a cycle: [param target] already reaches [param from] through pages (and events) held directly
static func would_loop(from: AdventurePage, target: AdventurePage) -> bool:
	return _get_held(target).has(from)

## [param root] and the pages (and events) it holds directly, not through transitions or host references
static func _get_held(root: AdventurePage) -> Array[AdventurePage]:
	var held: Array[AdventurePage] = [ ]
	var queue: Array[AdventurePage] = [root]
	while not queue.is_empty():
		var page: AdventurePage = queue.pop_front()
		if held.has(page): continue
		held.append(page)
		queue.append_array(page.events)
		for decision: AdventureDecision in page.decisions:
			if decision == null: continue
			for reference: AdventurePageReference in AdventureGraph.get_references(decision).values():
				if reference is AdventurePage: queue.append(reference as AdventurePage)
	return held

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

## In the [code]events[/code] folder next to the location's file
static func get_event_path(location: AdventurePage, title: String) -> String:
	return get_file_path(location).get_base_dir().path_join("events").path_join(AdventureMapEditing.get_file_name(title))

## Every kind of consequence there is (scripts extending [AdventureConsequence] that can be made), by class name
static func get_consequence_types() -> Dictionary[String, Script]:
	var bases: Dictionary[String, String] = {}
	var paths: Dictionary[String, String] = {}
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		bases[entry["class"]] = entry["base"]
		paths[entry["class"]] = entry["path"]
	var types: Dictionary[String, Script] = {}
	for type_name: String in bases:
		var base: String = bases[type_name]
		while bases.has(base) and base != "AdventureConsequence": base = bases[base]
		if base != "AdventureConsequence": continue
		var script: Script = load(paths[type_name])
		if script.can_instantiate(): types[type_name] = script
	return types

static func make_consequence(type: Script) -> AdventureConsequence:
	return _in_file(type.new() as Resource) as AdventureConsequence

## "AdventureKillMonsterConsequence" -> "Kill Monster"
static func get_consequence_type_name(type_name: String) -> String:
	return type_name.trim_prefix("Adventure").trim_suffix("Consequence").capitalize()

## Gives [param resource] its ID inside the file now, so the layout can key it before it is saved
static func _in_file(resource: Resource) -> Resource:
	resource.resource_scene_unique_id = Resource.generate_scene_unique_id()
	return resource
