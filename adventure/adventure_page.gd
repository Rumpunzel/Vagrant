@tool
class_name AdventurePage
extends AdventurePageReference

enum Exclusivity {
	NONE = 0,
	EXCLUDE_BASE = 1,
	EXCLUDE_BELOW = 2,
	EXCLUDE_ABOVE = 4,
}

@export_placeholder("Title") var _title: String
@export_multiline var _description: String
@export var _area: AdventureArea
@export var _background: Texture2D
@export var _ambience: AudioStream
@export var _conditions: Array[AdventureCondition]
@export var _decisions: Array[AdventureDecision]
@export_flags("Hide Base:1", "Hide Below:2", "Hide Above:4", "Hide All:7")
var _exclusivity: int = 0
@export var _events: Array[AdventurePage]

func are_all_prerequisites_fullfilled(_story: Story) -> bool:
	for condition: AdventureCondition in _conditions:
		if not condition.is_true(): return false
	return true

func prepare() -> void: pass

func get_page_title(story: Story) -> String:
	for event: AdventurePage in _events:
		if event.are_all_prerequisites_fullfilled(story):
			var event_title: String = event.get_page_title(story)
			if not event_title.is_empty(): return event_title
	if _area == null: return "%s" % _title if not _title.is_empty() else ""
	return "%s — %s" % [_area.name, _title]

func get_description(story: Story) -> String:
	var events: Array[AdventurePage] = get_events(story)
	var description: String = "" if _is_base_hidden(events) else "[p]%s[/p]" % _description
	for event: AdventurePage in events: description += event.get_description(story)
	return description

func get_background(story: Story) -> Texture2D:
	for event: AdventurePage in _events:
		if event.are_all_prerequisites_fullfilled(story):
			var event_background: Texture2D = event.get_background(story)
			if event_background: return event_background
	return _background

func get_area_background() -> Texture2D:
	return _area.background if _area else null

func get_ambience(story: Story) -> AudioStream:
	for event: AdventurePage in _events:
		if event.are_all_prerequisites_fullfilled(story):
			var event_ambience: AudioStream = event.get_ambience(story)
			if event_ambience != null: return event_ambience
	var area_ambience: AudioStream = _area.ambience if _area != null else null
	return _ambience if _ambience != null else area_ambience

func get_decisions(story: Story) ->  Array[AdventureDecision]:
	var events: Array[AdventurePage] = get_events(story)
	var decisions: Array[AdventureDecision] = [ ]
	for event: AdventurePage in events: decisions.append_array(event.get_decisions(story))
	if not _is_base_hidden(events): decisions.append_array(_decisions)
	return decisions

## Events whose prerequisites are met, in order. Hide Above drops the ones before an event, Hide Below the ones after it.
func get_events(story: Story) -> Array[AdventurePage]:
	var events: Array[AdventurePage] = [ ]
	for event: AdventurePage in _events:
		if not event.are_all_prerequisites_fullfilled(story): continue
		if event.exclude_above(): events = [ ]
		events.append(event)
		if event.exclude_below(): break
	return events

## Hide Base on any active event drops this page's own description and decisions
static func _is_base_hidden(events: Array[AdventurePage]) -> bool:
	for event: AdventurePage in events: if event.exclude_base(): return true
	return false

func exclude_base() -> bool:
	return _exclusivity & Exclusivity.EXCLUDE_BASE

func exclude_below() -> bool:
	return _exclusivity & Exclusivity.EXCLUDE_BELOW

func exclude_above() -> bool:
	return _exclusivity & Exclusivity.EXCLUDE_ABOVE

## The page (this one or a nested event) that defines [param decision], since [method get_decisions] flattens events
func find_decision_owner(decision: AdventureDecision) -> AdventurePage:
	if _decisions.has(decision): return self
	for event: AdventurePage in _events:
		var owner: AdventurePage = event.find_decision_owner(decision)
		if owner: return owner
	return null

func get_adventure_page() -> AdventurePage:
	return self
