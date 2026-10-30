@tool
class_name AdventureStageTrack
extends Resource

## One line of an encounter's or location's story: where it stands now is one of its stages (the first at the start).
## Several tracks keep apart what changes apart (the temple: intact / burned, its door closed / open).

@export var name: String
## Free states, not a ladder: storylines can branch
@export var stages: Array[String]

static func find(tracks: Array[AdventureStageTrack], track_name: String) -> AdventureStageTrack:
	for track: AdventureStageTrack in tracks: if track != null and track.name == track_name: return track
	return null

## The tracks of an encounter or location; none for anything else
static func get_tracks_of(subject: Resource) -> Array[AdventureStageTrack]:
	var tracks: Array[AdventureStageTrack] = [ ]
	if subject is AdventureEncounter: tracks = (subject as AdventureEncounter).tracks
	elif subject is AdventureLocation: tracks = (subject as AdventureLocation).tracks
	return tracks
