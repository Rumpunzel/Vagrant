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
