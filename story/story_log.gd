extends Node

signal decision_made(story_decision: StoryDecision, selected_how_many_times: int)
signal page_entered(story_page: StoryPage)

var current_page: StoryPage

# StoryDecision -> int (how many times the decision has been made)
var _decision_log := { }
# StorySaveDecision -> Array[SaveResult]
var _save_decision_log := { }
# StoryPage -> int (how many times the page has been entered)
var _page_log := { }
var _page_stack: Array[StoryPage] = [ ]

func make_decision(story_decision: StoryDecision) -> int:
	var selected_how_many_times: int = -1
	if story_decision != StoryDecision.get_continue():
		selected_how_many_times = _update_decision_log(story_decision)
	decision_made.emit(story_decision, selected_how_many_times)
	enter_page(story_decision.transition.get_story_page())
	return selected_how_many_times

func make_save_decision(story_save_decision: StorySaveDecision, save_result: SaveResult) -> int:
	var save_results: Array[SaveResult] = _save_decision_log.get(story_save_decision, [ ] as Array[SaveResult])
	save_results.append(save_result)
	var selected_how_many_times := save_results.size()
	_save_decision_log[story_save_decision] = save_results
	decision_made.emit(story_save_decision, selected_how_many_times)
	if save_result.save_outcome != SaveResult.Outcome.FAILURE:
		enter_page(story_save_decision.transition.get_story_page())
	else:
		enter_page(story_save_decision.failure_transition.get_story_page())
	return selected_how_many_times

func enter_page(story_page: StoryPage) -> StoryPage:
	if story_page == null: story_page = _page_stack.pop_back()
	elif current_page == story_page:
		print_debug("Already on page: <%s>!" % current_page)
		return
	_page_log[story_page] = get_how_often_page_has_been_entered(story_page) + 1
	for event: StoryPage in story_page.get_events():
		_page_log[event] = get_how_often_page_has_been_entered(event) + 1
	_page_stack.push_back(current_page)
	current_page = story_page
	page_entered.emit(current_page)
	return current_page

func get_how_often_decision_has_been_made(story_decision: StoryDecision) -> int:
	if story_decision is StorySaveDecision:
		return _save_decision_log.get(story_decision, [ ]).size()
	return _decision_log.get(story_decision, 0)

func get_how_often_page_has_been_entered(story_page: StoryPage) -> int:
	return _page_log.get(story_page, 0)

func _update_decision_log(story_decision: StoryDecision) -> int:
	var selected_how_many_times: int = get_how_often_decision_has_been_made(story_decision) + 1
	_decision_log[story_decision] = selected_how_many_times
	return selected_how_many_times
