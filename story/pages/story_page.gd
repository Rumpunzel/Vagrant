class_name StoryPage
extends StoryPageReference

enum Exclusivity {
	NONE = 0,
	EXCLUDE_BASE = 1,
	EXCLUDE_BELOW = 2,
	EXCLUDE_ABOVE = 4,
}

@export_placeholder("Title") var _title: String
@export_multiline var _description: String
@export var _area: StoryArea
@export var _background: Texture
@export var _ambience: AudioStream
@export var _one_time_only: bool = false
@export var _conditions: Array[StoryCondition]
@export var _decisions: Array[StoryDecision]
@export_flags("Hide Base:1", "Hide Below:2", "Hide Above:4", "Hide All:7")
var _exclusivity: int = 0
@export var _events: Array[StoryPage]

func are_all_prerequisites_fullfilled() -> bool:
	if _one_time_only and Story.get_how_often_page_has_been_entered(self) > 1: return false
	for condition: StoryCondition in _conditions:
		if condition.is_true(): return true
	return _conditions.is_empty()

func get_page_title() -> String:
	for event: StoryPage in _events:
		if event.are_all_prerequisites_fullfilled():
			var event_title: String = event.get_page_title()
			if not event_title.is_empty(): return event_title
	if _area == null: return "%s" % _title if not _title.is_empty() else ""
	return "%s — %s" % [_area.name, _title]

func get_description() -> String:
	var combined_description: String = ""
	for event: StoryPage in _events:
		if event.are_all_prerequisites_fullfilled():
			if event.exclude_above(): combined_description = ""
			combined_description += "%s" % event.get_description()
			if event.exclude_below():
				if event.exclude_base(): return combined_description
				else: break
	return ("[p]%s[/p]" % _description) + combined_description

func get_background() -> Texture:
	for event: StoryPage in _events:
		if event.are_all_prerequisites_fullfilled():
			var event_background: Texture = event.get_background()
			if event_background != null: return event_background
	var area_background: Texture = _area.background if _area != null else null
	return _background if _background != null else area_background

func get_ambience() -> AudioStream:
	var area_ambience: AudioStream = _area.ambience if _area != null else null
	return _ambience if _ambience != null else area_ambience

func get_decisions() ->  Array[StoryDecision]:
	var combined_decisions: Array[StoryDecision] = [ ]
	for event: StoryPage in _events:
		if event.are_all_prerequisites_fullfilled():
			if event.exclude_above(): combined_decisions = [ ]
			combined_decisions.append_array(event.get_decisions())
			if event.exclude_below():
				if event.exclude_base(): return combined_decisions
				else: break
	combined_decisions.append_array(_decisions)
	return combined_decisions

func get_events() -> Array[StoryPage]:
	var events: Array[StoryPage] = [ ]
	for event: StoryPage in _events:
		if event.are_all_prerequisites_fullfilled():
			if event.exclude_above(): events = [ ]
			events.append(event)
			if event.exclude_below():
				if event.exclude_base(): return events
				else: break
	return events

func exclude_base() -> bool:
	return _exclusivity & Exclusivity.EXCLUDE_BELOW

func exclude_below() -> bool:
	return _exclusivity & Exclusivity.EXCLUDE_BELOW

func exclude_above() -> bool:
	return _exclusivity & Exclusivity.EXCLUDE_ABOVE

func get_story_page() -> StoryPage:
	return self
