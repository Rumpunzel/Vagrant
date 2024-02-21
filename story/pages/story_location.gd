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
	return "[center]%s — %s[/center]" % [area.name, name]

func get_description() -> String:
	var combined_description := super.get_description()
	for event: StoryEvent in events:
		if event.are_all_prerequisites_fullfilled():
			if event.exclusive: return event.get_description()
			combined_description += event.get_description()
	return combined_description

func get_decisions() ->  Array[StoryDecision]:
	var combined_decisions: Array[StoryDecision]= [ ]
	for event: StoryEvent in events:
		if event.are_all_prerequisites_fullfilled():
			if event.exclusive: return event.get_decisions()
			combined_decisions.append_array(event.get_decisions())
	combined_decisions.append_array(super.get_decisions())
	return combined_decisions

func get_thumbnail() -> Texture:
	for event: StoryEvent in events:
		if event.are_all_prerequisites_fullfilled():
			if event.get_thumbnail() != null: return event.get_thumbnail()
			if event.exclusive: break
	return super.get_thumbnail() if super.get_thumbnail() != null else background
