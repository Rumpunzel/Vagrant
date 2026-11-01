@tool
class_name AdventureMakers
extends RefCounted

## New things for the adventure editor: pages, decisions, events, encounters, tracks, conditions and effects, locations and areas, and where their
## files go. Resources to be stored inside a file get their ID there right away ([method _in_file]), so the layout can key them before saving.
## The changes that put them somewhere: [AdventureEventEditing], [AdventureMapEditing].

## A scenario picking all that fit, to be stored inside a location's file as its own events
static func make_scenario() -> AdventureEventScenario:
	var scenario: AdventureEventScenario = _in_file(AdventureEventScenario.new()) as AdventureEventScenario
	scenario.pick = AdventureEventScenario.Pick.ALL
	return scenario

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
	var folder: String = AdventureEventEditing.get_file_path(host).get_base_dir()
	if folder.get_file() != "events": folder = folder.path_join("events")
	return folder.path_join(get_file_name(title))

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

## "It can fight" (is beaten, is dead): about the event's own encounter's monster
static func make_monster_condition(state: AdventureMonsterCondition.State) -> AdventureMonsterCondition:
	var condition: AdventureMonsterCondition = _in_file(AdventureMonsterCondition.new()) as AdventureMonsterCondition
	condition.state = state
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
	var file_name: String = get_file_name(title)
	return adventure.resource_path.get_base_dir().path_join("encounters").path_join(file_name.get_basename()).path_join(file_name)

## A new encounter that could be at [param location], with its files (path -> resource, in saving order: what the encounter points at first).
## An NPC gets a Storyline (Unmet / Met); with [param profile] a monster gets an ambush while it can fight (winning beats it), going back to where
## it happened; its body is its monster's, so it needs no track.
static func make_encounter_files(adventure: Adventure, title: String, location: AdventureLocation, profile: MonsterProfile = null) -> Dictionary[String, Resource]:
	var files: Dictionary[String, Resource] = {}
	var path: String = get_encounter_path(adventure, title)
	var encounter: AdventureEncounter = AdventureEncounter.new()
	encounter.title = title
	encounter.profile = profile
	encounter.places = [AdventureLayout.get_key(location)] as Array[String]
	if profile == null:
		var track: AdventureStageTrack = make_track("Storyline")
		track.stages = ["Unmet", "Met"] as Array[String]
		encounter.tracks = [track] as Array[AdventureStageTrack]
	else:
		var ambush: AdventureEvent = AdventureEvent.new()
		ambush.title = "%s Ambush" % title
		ambush.exclusivity = AdventureEvent.Exclusivity.EXCLUDE_BASE | AdventureEvent.Exclusivity.EXCLUDE_BELOW | AdventureEvent.Exclusivity.EXCLUDE_ABOVE
		ambush.conditions = [make_monster_condition(AdventureMonsterCondition.State.CAN_FIGHT)] as Array[AdventureCondition]
		var fight: AdventureFightDecision = make_fight()
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

## A plain decision leading to [param to]
static func make_link(to: AdventurePage) -> AdventureDecision:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.description = "Go to %s." % AdventureGraph.get_title(to)
	decision.transition = AdventureTransition.leading_to(to)
	return decision

static func make_location(title: String, area: AdventureArea) -> AdventureLocation:
	var location: AdventureLocation = AdventureLocation.new()
	location.title = title
	location.area = area
	return location

static func make_area(area_name: String) -> AdventureArea:
	var area: AdventureArea = AdventureArea.new()
	area.name = area_name
	return area

## Next to the area's file
static func get_location_path(area: AdventureArea, title: String) -> String:
	return area.resource_path.get_base_dir().path_join(get_file_name(title))

## In its own folder under [code]locations[/code] next to the adventure
static func get_area_path(adventure: Adventure, area_name: String) -> String:
	return adventure.resource_path.get_base_dir().path_join("locations").path_join(get_file_name(area_name).get_basename()).path_join(get_file_name(area_name))

## Snake case; every run of other characters than letters and digits becomes one "_"
static func get_file_name(title: String) -> String:
	var words: String = RegEx.create_from_string("[^\\p{L}\\p{N}]+").sub(title.to_snake_case(), "_", true).trim_prefix("_").trim_suffix("_")
	return (words if not words.is_empty() else "untitled") + ".tres"
