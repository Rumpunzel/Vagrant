class_name StoryPage
extends StoryPageReference

@export var exclusive := false

@export_placeholder("Title") var _title: String
@export_multiline var _description: String
@export var _area: StoryArea
@export var _background: Texture
@export var _ambience: AudioStream
@export var _one_time_only := false
@export var _conditions: Array[StoryCondition]
@export var _decisions: Array[StoryDecision]
@export var _events: Array[StoryPage]

func are_all_prerequisites_fullfilled() -> bool:
	if _one_time_only and Story.get_how_often_page_has_been_entered(self) > 1: return false
	for condition: StoryCondition in _conditions:
		if condition.is_true(): return true
	return _conditions.is_empty()

func get_page_title() -> String:
	for event: StoryPage in _events:
		if event.are_all_prerequisites_fullfilled():
			var event_title := event.get_page_title()
			if not event_title.is_empty(): return event_title
	if _area == null: return "[center]%s[/center]" % _title if not _title.is_empty() else ""
	return "[center]%s — %s[/center]" % [_area.name, _title]

func get_description() -> String:
	var combined_description := ""
	for event: StoryPage in _events:
		if event.are_all_prerequisites_fullfilled():
			combined_description += "%s" % event.get_description()
			if event.exclusive: return combined_description
	return ("[p]%s[/p]" % _description) + combined_description

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
			combined_decisions.append_array(event.get_decisions())
			if event.exclusive: return combined_decisions
	combined_decisions.append_array(_decisions)
	return combined_decisions

func get_events() -> Array[StoryPage]:
	var events: Array[StoryPage]= [ ]
	for event: StoryPage in _events:
		if event.are_all_prerequisites_fullfilled():
			events.append(event)
			if event.exclusive: return events
	return events

func get_story_page() -> StoryPage:
	return self
