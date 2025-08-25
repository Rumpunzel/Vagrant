class_name Adventure
extends Node

@export var adventure: AdventureTome

var current_page: StoryPage

# StoryDecision -> int (how many times the decision has been made)
var _decision_log: Dictionary[StoryDecision, int] = { }
# StorySaveDecision -> Array[SaveResult]
var _save_decision_log: Dictionary[StorySaveDecision, Array]= { }
# StoryPage -> int (how many times the page has been entered)
var _page_log: Dictionary[StoryPage, int] = { }
var _page_stack: Array[StoryPage] = [ ]

func _ready() -> void:
	Story.start_adventure(self)

func get_how_often_decision_has_been_made(story_decision: StoryDecision) -> int:
	if story_decision is StorySaveDecision:
		return _save_decision_log.get(story_decision, [ ]).size()
	return _decision_log.get(story_decision, 0)

func get_how_often_page_has_been_entered(story_page: StoryPage) -> int:
	return _page_log.get(story_page, 0)

func update_decision_log(story_decision: StoryDecision) -> int:
	var selected_how_many_times: int = get_how_often_decision_has_been_made(story_decision) + 1
	_decision_log[story_decision] = selected_how_many_times
	return selected_how_many_times

func update_save_decision_log(story_save_decision: StorySaveDecision, save_result: SaveResult) -> int:
	var save_results: Array[SaveResult] = _save_decision_log.get(story_save_decision, [ ] as Array[SaveResult])
	save_results.append(save_result)
	var selected_how_many_times: int = save_results.size()
	_save_decision_log[story_save_decision] = save_results
	return selected_how_many_times

func update_page_log(story_page: StoryPage) -> StoryPage:
	if story_page == null: story_page = _page_stack.pop_back()
	elif current_page == story_page:
		print_debug("Already on page: <%s>!" % current_page)
		return
	_page_log[story_page] = get_how_often_page_has_been_entered(story_page) + 1
	for event: StoryPage in story_page.get_events():
		_page_log[event] = get_how_often_page_has_been_entered(event) + 1
	_page_stack.push_back(current_page)
	current_page = story_page
	return current_page
