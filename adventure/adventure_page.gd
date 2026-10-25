@tool
class_name AdventurePage
extends AdventurePageReference

enum Exclusivity {
	NONE = 0,
	EXCLUDE_BASE = 1,
	EXCLUDE_BELOW = 2,
	EXCLUDE_ABOVE = 4,
}

@export_placeholder("Title") var title: String
@export_multiline var description: String
@export var area: AdventureArea
@export var background: Texture2D
@export var ambience: AudioStream
@export var conditions: Array[AdventureCondition]
@export var decisions: Array[AdventureDecision]
@export_flags("Hide Base:1", "Hide Below:2", "Hide Above:4", "Hide All:7")
var exclusivity: int = 0
@export var events: Array[AdventurePage]

func are_all_prerequisites_fullfilled(story: Story) -> bool:
	for condition: AdventureCondition in conditions:
		if not condition.is_true(story, self): return false
	return true

func prepare() -> void: pass

func get_page_title(story: Story) -> String:
	for event: AdventurePage in events:
		if event.are_all_prerequisites_fullfilled(story):
			var event_title: String = event.get_page_title(story)
			if not event_title.is_empty(): return event_title
	if area == null: return "%s" % title if not title.is_empty() else ""
	return "%s — %s" % [area.name, title]

func get_description(story: Story) -> String:
	var active_events: Array[AdventurePage] = get_events(story)
	var text: String = "" if _is_base_hidden(active_events) else "[p]%s[/p]" % description
	for event: AdventurePage in active_events: text += event.get_description(story)
	return text

func get_background(story: Story) -> Texture2D:
	for event: AdventurePage in events:
		if event.are_all_prerequisites_fullfilled(story):
			var event_background: Texture2D = event.get_background(story)
			if event_background: return event_background
	return background

func get_area_background() -> Texture2D:
	return area.background if area else null

func get_ambience(story: Story) -> AudioStream:
	for event: AdventurePage in events:
		if event.are_all_prerequisites_fullfilled(story):
			var event_ambience: AudioStream = event.get_ambience(story)
			if event_ambience != null: return event_ambience
	var area_ambience: AudioStream = area.ambience if area != null else null
	return ambience if ambience != null else area_ambience

func get_decisions(story: Story) ->  Array[AdventureDecision]:
	var active_events: Array[AdventurePage] = get_events(story)
	var active_decisions: Array[AdventureDecision] = [ ]
	for event: AdventurePage in active_events: active_decisions.append_array(event.get_decisions(story))
	if not _is_base_hidden(active_events): active_decisions.append_array(decisions)
	return active_decisions

## Events whose prerequisites are met, in order. Hide Above drops the ones before an event, Hide Below the ones after it.
func get_events(story: Story) -> Array[AdventurePage]:
	var active_events: Array[AdventurePage] = [ ]
	for event: AdventurePage in events:
		if not event.are_all_prerequisites_fullfilled(story): continue
		if event.exclude_above(): active_events = [ ]
		active_events.append(event)
		if event.exclude_below(): break
	return active_events

## Hide Base on any active event drops this page's own description and decisions
static func _is_base_hidden(active_events: Array[AdventurePage]) -> bool:
	for event: AdventurePage in active_events: if event.exclude_base(): return true
	return false

func exclude_base() -> bool:
	return exclusivity & Exclusivity.EXCLUDE_BASE

func exclude_below() -> bool:
	return exclusivity & Exclusivity.EXCLUDE_BELOW

func exclude_above() -> bool:
	return exclusivity & Exclusivity.EXCLUDE_ABOVE

## The page (this one or a nested event) that defines [param decision], since [method get_decisions] flattens events
func find_decision_owner(decision: AdventureDecision) -> AdventurePage:
	if decisions.has(decision): return self
	for event: AdventurePage in events:
		var owner: AdventurePage = event.find_decision_owner(decision)
		if owner: return owner
	return null

func get_adventure_page() -> AdventurePage:
	return self
