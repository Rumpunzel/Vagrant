@tool
class_name StoryLocation
extends StoryPage

@export_placeholder("Name") var name: String
@export var area: StoryArea
@export var events: Array[StoryPage]

@export var _ambience: AudioStream = null

func to_page_subtitle() -> String:
	if area == null: return name
	return "[center]%s — %s[/center]" % [area.name, name]

func get_description() -> String:
	var combined_description := super.get_description()
	for event: StoryPage in events:
		if event.are_all_prerequisites_fullfilled():
			if event.exclusive: return event.get_description()
			combined_description += event.get_description()
	return combined_description

func get_decisions() ->  Array[StoryDecision]:
	var combined_decisions: Array[StoryDecision]= [ ]
	for event: StoryPage in events:
		if event.are_all_prerequisites_fullfilled():
			if event.exclusive: return event.get_decisions()
			combined_decisions.append_array(event.get_decisions())
	combined_decisions.append_array(super.get_decisions())
	return combined_decisions

func get_background() -> Texture:
	for event: StoryPage in events:
		if event.are_all_prerequisites_fullfilled():
			if event.get_background() != null: return event.get_background()
			if event.exclusive: break
	return super.get_background() if super.get_background() != null else area.background

func get_ambience() -> AudioStream:
	return _ambience if _ambience != null else area.ambience
