@tool
class_name AdventurePage
extends AdventurePageReference

## A page of the story: what it says and what one can do there. Pages behind events are plain pages;
## [AdventureLocation]s also show events, [AdventureEvent]s are what they show.

@export_placeholder("Title") var title: String
@export_multiline var description: String
@export var background: Texture2D
@export var ambience: AudioStream
@export var decisions: Array[AdventureDecision]

func prepare() -> void: pass

func get_page_title(_story: Story) -> String: return title

func get_description(_story: Story) -> String: return "[p]%s[/p]" % description

func get_background(_story: Story) -> Texture2D: return background

func get_area_background() -> Texture2D: return null

func get_ambience(_story: Story) -> AudioStream: return ambience

func get_decisions(_story: Story) -> Array[AdventureDecision]: return decisions.duplicate()

## The events shown on it; a plain page shows none
func get_events(_story: Story) -> Array[AdventureEvent]:
	var none: Array[AdventureEvent] = [ ]
	return none

## The events its file stores with it
func get_held_events() -> Array[AdventureEvent]:
	var none: Array[AdventureEvent] = [ ]
	return none

## This page and the pages (and events) it holds directly, not through transitions or host links: what its file stores with it
func get_held_pages() -> Array[AdventurePage]:
	var held: Array[AdventurePage] = [ ]
	var queue: Array[AdventurePage] = [self]
	while not queue.is_empty():
		var page: AdventurePage = queue.pop_front()
		if page == null or held.has(page): continue
		held.append(page)
		queue.append_array(page.get_held_events())
		for decision: AdventureDecision in page.decisions:
			if decision == null: continue
			for link: AdventurePageReference in decision.get_page_references(): if link is AdventurePage: queue.append(link as AdventurePage)
	return held

## The page (this one or a nested event) that defines [param decision], since [method get_decisions] flattens events
func find_decision_owner(decision: AdventureDecision) -> AdventurePage:
	return self if decisions.has(decision) else null

func get_adventure_page() -> AdventurePage:
	return self
