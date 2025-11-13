@tool
class_name Story
extends Node

signal decision_made(story_decision: StoryDecision, selected_how_many_times: int)
signal page_entered(story_page: StoryPage)

var _current_adventure: Adventure
var _current_adventure_tome: AdventureTome :
	get: return _current_adventure.adventure_tome

func start_adventure(adventure: Adventure) -> void:
	assert(adventure)
	if _current_adventure != null:
		print_debug("Trying to start an adventure while there is already an ongoing one!")
		return
	_current_adventure = adventure
	enter_page(_current_adventure_tome.starting_page)

func make_decision(story_decision: StoryDecision) -> int:
	assert(story_decision)
	var selected_how_many_times: int = -1
	if story_decision != StoryDecision.get_continue():
		selected_how_many_times = _current_adventure.update_decision_log(story_decision)
	decision_made.emit(story_decision, selected_how_many_times)
	enter_page(story_decision.transition.get_story_page())
	return selected_how_many_times

func make_save_decision(story_save_decision: StorySaveDecision, save_result: SaveResult) -> int:
	assert(story_save_decision)
	assert(save_result)
	var selected_how_many_times: int = _current_adventure.update_save_decision_log(story_save_decision, save_result)
	decision_made.emit(story_save_decision, selected_how_many_times)
	if save_result.get_save_outcome() != SaveResult.Outcome.FAILURE:
		enter_page(story_save_decision.transition.get_story_page())
	else:
		enter_page(story_save_decision.failure_transition.get_story_page())
	return selected_how_many_times

func make_fight_decision(story_fight_decision: StoryFightDecision, fight_result: FightResult) -> int:
	assert(story_fight_decision)
	assert(fight_result)
	var selected_how_many_times: int = _current_adventure.update_fight_decision_log(story_fight_decision, fight_result)
	decision_made.emit(story_fight_decision, selected_how_many_times)
	#if fight_result.get_save_outcome() != SaveResult.Outcome.FAILURE:
		#enter_page(story_fight_decision.transition.get_story_page())
	#else:
		#enter_page(story_fight_decision.failure_transition.get_story_page())
	#else:
	enter_page(_current_adventure.current_page)
	return selected_how_many_times

func enter_page(story_page: StoryPage) -> StoryPage:
	var current_page: StoryPage = _current_adventure.update_page_log(story_page)
	page_entered.emit(current_page)
	return current_page

func get_how_often_decision_has_been_made(story_decision: StoryDecision) -> int:
	return _current_adventure.get_how_often_decision_has_been_made(story_decision)

func get_how_often_page_has_been_entered(story_page: StoryPage) -> int:
	return _current_adventure.get_how_often_page_has_been_entered(story_page)
