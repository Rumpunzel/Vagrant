@tool
class_name AdventureStageCondition
extends AdventureCondition

## True while a track of an encounter or location is at one of [member stages]

## By UID; empty: the event's own encounter, or the current location for a location's own events
@export_file("*.tres") var subject: String:
	set(value):
		subject = value
		notify_property_list_changed()
@export var track: String:
	set(value):
		track = value
		notify_property_list_changed()
@export var stages: Array[String]

func is_true(story: Story, page: AdventurePage) -> bool:
	var target: Resource = story.get_subject(subject, page)
	return target != null and stages.has(story.world.get_stage(target, track))

func describe() -> String:
	return "%s: %s is %s" % [AdventureStageCondition.name_subject(subject), track, " or ".join(stages)]

## "Eleanor"; "its own" for an empty subject
static func name_subject(path: String) -> String:
	var target: Resource = Files.load_existing(path)
	if target is AdventurePage and not (target as AdventurePage).title.is_empty(): return (target as AdventurePage).title
	return "its own" if path.is_empty() else path.get_file().get_basename().capitalize()

## Dropdowns from the subject's tracks, when it is set
func _validate_property(property: Dictionary) -> void:
	AdventureStageCondition.offer_stages(property, subject, track, &"track", &"stages")

static func offer_stages(property: Dictionary, subject_path: String, track_name: String, track_property: StringName, stage_property: StringName) -> void:
	var tracks: Array[AdventureStageTrack] = AdventureStageTrack.get_tracks_of(Files.load_existing(subject_path))
	if tracks.is_empty(): return
	if property.name == track_property:
		property.hint = PROPERTY_HINT_ENUM_SUGGESTION
		property.hint_string = ",".join(tracks.map(func(each: AdventureStageTrack) -> String: return each.name))
	var chosen: AdventureStageTrack = AdventureStageTrack.find(tracks, track_name)
	if property.name != stage_property or chosen == null: return
	var names: String = ",".join(chosen.stages)
	if property.type == TYPE_ARRAY:
		property.hint = PROPERTY_HINT_TYPE_STRING
		property.hint_string = "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_ENUM_SUGGESTION, names]
	else:
		property.hint = PROPERTY_HINT_ENUM_SUGGESTION
		property.hint_string = names
