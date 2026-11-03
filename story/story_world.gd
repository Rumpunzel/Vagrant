class_name StoryWorld
extends RefCounted

## Where the story stands: each encounter's and location's stage per track, and where each encounter could be

signal stage_set(subject: Resource, track_name: String, stage: String)
signal moved(encounter: AdventureEncounter, places: Array[AdventureLocation])

var _encounters: Array[AdventureEncounter] = [ ]
## { subject -> { track name -> stage } }; unset tracks are at their first stage
var _stages: Dictionary[Resource, Dictionary] = {}
## { encounter -> Array[AdventureLocation] }; unset: its [member AdventureEncounter.places]
var _places: Dictionary[AdventureEncounter, Array] = {}
var _encounter_of: Dictionary[AdventureEvent, AdventureEncounter] = {}
## Links from each location, found once ([method AdventureLocation.get_distances])
var _distances: Dictionary[AdventureLocation, Dictionary] = {}

func _init(encounters: Array[AdventureEncounter] = [ ]) -> void:
	for encounter: AdventureEncounter in encounters:
		if encounter == null: continue
		_encounters.append(encounter)
		for event: AdventureEvent in encounter.get_listed_events(): _encounter_of[event] = encounter

func get_encounters() -> Array[AdventureEncounter]: return _encounters.duplicate()

## The encounter [param event] is one of the events of; none for a location's own events
func get_encounter_of(event: AdventureEvent) -> AdventureEncounter:
	if event is AdventureEncounter: return event as AdventureEncounter
	return _encounter_of.get(event)

func get_stage(subject: Resource, track_name: String) -> String:
	var set_stages: Dictionary = _stages.get(subject, {})
	if set_stages.has(track_name): return set_stages[track_name]
	var track: AdventureStageTrack = AdventureStageTrack.find(AdventureStageTrack.get_tracks_of(subject), track_name)
	return track.stages[0] if track != null and not track.stages.is_empty() else ""

func set_stage(subject: Resource, track_name: String, stage: String) -> void:
	var set_stages: Dictionary = _stages.get_or_add(subject, {})
	set_stages[track_name] = stage
	stage_set.emit(subject, track_name, stage)

func get_places(encounter: AdventureEncounter) -> Array[AdventureLocation]:
	var places: Array[AdventureLocation] = [ ]
	if _places.has(encounter): places.assign(_places[encounter])
	else: places = encounter.get_places()
	return places

func move(encounter: AdventureEncounter, places: Array[AdventureLocation]) -> void:
	_places[encounter] = places.duplicate()
	moved.emit(encounter, places)

## Whether [param location] is within [param reach] links of where [param encounter] could be (0: anywhere in the same area),
## but not one of those places itself
func is_near(encounter: AdventureEncounter, location: AdventureLocation, reach: int, stays_in_area: bool) -> bool:
	var places: Array[AdventureLocation] = get_places(encounter)
	if places.has(location): return false
	for place: AdventureLocation in places:
		if not _distances.has(place): _distances[place] = place.get_distances()
		var distances: Dictionary = _distances[place]
		if not distances.has(location): continue
		if (reach == 0 or stays_in_area) and location.area != place.area: continue
		if reach > 0 and int(distances[location]) > reach: continue
		return true
	return false
