@tool
class_name StoryLocation
extends StoryPage

@export_placeholder("Name") var name: String
@export var area: StoryArea
@export var background: Texture = null :
	get: return background if background != null else area.background
@export var ambience: AudioStream = null :
	get: return ambience if ambience != null else area.ambience
@export var events: Array[StoryEvent]

func to_page_subtitle() -> String:
	if area == null: return name
	return "[center]%s - %s[/center]" % [area.name, name]

func _get_description() -> String:
	var combined_description := "[p]%s[/p]" % description
	for event: StoryEvent in events:
		if event.are_all_prerequisites_fullfilled():
			if event.exclusive: return event.description
			combined_description += "[p]%s[/p]" % event.description
	return combined_description

func _get_decisions() ->  Array[StoryDecision]:
	var combined_decisions: Array[StoryDecision]= [ ]
	for event: StoryEvent in events:
		if event.are_all_prerequisites_fullfilled():
			if event.exclusive: return event.decisions
			combined_decisions.append_array(event.decisions)
	combined_decisions.append_array(decisions)
	return combined_decisions

func _get_thumbnail() -> Texture:
	for event: StoryEvent in events:
		if event.are_all_prerequisites_fullfilled():
			if event.thumbnail != null: return event.thumbnail
			if event.exclusive: break
	return thumbnail if thumbnail != null else background
