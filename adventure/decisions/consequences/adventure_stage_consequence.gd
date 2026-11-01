@tool
class_name AdventureStageConsequence
extends AdventureConsequence

## Sets a track of an encounter or location to [member stage]

## By UID; empty: the encounter of the event one is in, else the current location
@export_file("*.tres") var subject: String:
	set(value):
		subject = value
		notify_property_list_changed()
@export var track: String:
	set(value):
		track = value
		notify_property_list_changed()
@export var stage: String

func resolve(story: Story, _margin: int) -> void:
	var target: Resource = story.get_subject(subject, null)
	if target != null: story.world.set_stage(target, track, stage)

func describe() -> String:
	return "%s → %s" % [AdventureStageCondition.name_subject(subject), stage]

func _validate_property(property: Dictionary) -> void:
	AdventureStageCondition.offer_stages(property, subject, track, &"track", &"stage")
