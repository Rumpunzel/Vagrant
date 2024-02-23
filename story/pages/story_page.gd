@tool
class_name StoryPage
extends StoryPageReference

@export var exclusive := false

@export_placeholder("Title") var _title: String
@export var _placeholder := true
@export_multiline var _description: String
@export var _area: StoryArea
@export var _background: Texture
@export var _ambience: AudioStream
@export var _decisions: Array[StoryDecision]
@export var _events: Array[StoryPage]

func are_all_prerequisites_fullfilled() -> bool:
	return _placeholder

func get_page_title() -> String:
	for event: StoryPage in _events:
		if event.are_all_prerequisites_fullfilled():
			var event_title := event.get_page_title()
			if not event_title.is_empty(): return event_title
	if _area == null: return "[center]%s[/center]" % _title if not _title.is_empty() else ""
	return "[center]%s — %s[/center]" % [_area.name, _title]

func get_description() -> String:
	var combined_description := "[p]%s[/p]" % _description
	for event: StoryPage in _events:
		if event.are_all_prerequisites_fullfilled():
			if event.exclusive: return event.get_description()
			combined_description += event.get_description()
	return combined_description

func get_background() -> Texture:
	for event: StoryPage in _events:
		if event.are_all_prerequisites_fullfilled():
			var event_background := event.get_background()
			if event_background != null: return event_background
	var area_background := _area.background if _area != null else null
	return _background if _background != null else area_background

func get_ambience() -> AudioStream:
	var area_ambience := _area.ambience if _area != null else null
	return _ambience if _ambience != null else area_ambience

func get_decisions() ->  Array[StoryDecision]:
	var combined_decisions: Array[StoryDecision]= [ ]
	for event: StoryPage in _events:
		if event.are_all_prerequisites_fullfilled():
			if event.exclusive: return event.get_decisions()
			combined_decisions.append_array(event.get_decisions())
	combined_decisions.append_array(_decisions)
	return combined_decisions

func get_story_page() -> StoryPage:
	return self
