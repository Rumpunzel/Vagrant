@tool
class_name Story
extends Node

signal story_book_page_entered(story_book_page: StoryBookPage)
signal decision_made(story_decision: StoryDecision, selected_how_many_times: int)

@export_group("Configuration")
@export var _party: Characters
@export var _title: TypingLabel

var adventure: Adventure :
	set(new_adventure):
		assert(not adventure or Engine.is_editor_hint())
		assert(new_adventure or Engine.is_editor_hint())
		adventure = new_adventure
		if not adventure: return
		_title.type_text(adventure.title)
var protagonist: Character

var current_story_book_page: StoryBookPage :
	set(story_book_page):
		if story_book_page == null: story_book_page = _page_stack.pop_back()
		#elif current_page == story_page:
			#print_debug("Already on page: <%s>!" % current_page)
			#return
		_page_stack.push_back(current_story_book_page)
		current_story_book_page = story_book_page
		var page_log: Array[StoryBookPage] = _page_log.get_or_add(current_story_book_page.story_page, [] as Array[StoryBookPage])
		page_log.append(current_story_book_page)
		#for event: StoryPage in current_story_book_page.get_events(self): _page_log[event] = get_how_often_page_has_been_entered(event) + 1
		@warning_ignore("unsafe_method_access")
		Stage.enter_story_book_page(current_story_book_page)
		story_book_page_entered.emit(current_story_book_page)

var _current_dice_request: DiceRequest :
	set(new_dice_request):
		_current_dice_request = new_dice_request

# StoryDecision -> int (how many times the decision has been made)
var _decision_log: Dictionary[StoryDecision, int] = { }
# StorySaveDecision -> Array[SaveResult]
var _save_decision_log: Dictionary[StorySaveDecision, Array]= { }
# StoryFightDecision -> Array[FightResult]
var _fight_decision_log: Dictionary[StoryFightDecision, Array]= { }
# StoryBookPage -> Array[StoryBookPage]
var _page_log: Dictionary[StoryPage, Array] = { }
var _page_stack: Array[StoryBookPage] = [ ]

func start_adventure(new_adventure: Adventure, protagonist_profile: CharacterProfile) -> void:
	assert(new_adventure)
	assert(protagonist_profile)
	assert(protagonist_profile.is_valid())
	adventure = new_adventure
	protagonist = _party.create_character(protagonist_profile)
	enter_page(adventure.starting_page)

func enter_page(story_page: StoryPage) -> void:
	current_story_book_page = _create_story_book_page(story_page)

func make_decision(story_decision: StoryDecision) -> void:
	assert(story_decision)
	var selected_how_many_times: int = -1
	if story_decision != StoryDecision.get_continue():
		selected_how_many_times = get_how_often_decision_has_been_made(story_decision) + 1
		_decision_log[story_decision] = selected_how_many_times
	decision_made.emit(story_decision, selected_how_many_times)
	enter_page(story_decision.transition.get_story_page())

func request_save(save_request: SaveRequest) -> void:
	_current_dice_request = save_request

func get_requested_save() -> SaveRequest:
	if not _current_dice_request is SaveRequest: return null
	return _current_dice_request

func make_save_decision(story_save_decision: StorySaveDecision, save_result: SaveResult) -> void:
	assert(story_save_decision)
	assert(save_result)
	var save_results: Array[SaveResult] = _save_decision_log.get(story_save_decision, [ ] as Array[SaveResult])
	save_results.append(save_result)
	var selected_how_many_times: int = save_results.size()
	_save_decision_log[story_save_decision] = save_results
	decision_made.emit(story_save_decision, selected_how_many_times)
	if save_result.get_save_outcome() != SaveResult.Outcome.FAILURE:
		enter_page(story_save_decision.transition.get_story_page())
	else:
		enter_page(story_save_decision.failure_transition.get_story_page())

func request_fight(fight_request: FightRequest) -> void:
	_current_dice_request = fight_request

func get_requested_fight() -> FightRequest:
	if not _current_dice_request is FightRequest: return null
	return _current_dice_request

func make_fight_decision(story_fight_decision: StoryFightDecision, fight_result: FightResult) -> void:
	assert(story_fight_decision)
	assert(fight_result)
	var fight_results: Array[FightResult] = _fight_decision_log.get(story_fight_decision, [ ] as Array[FightResult])
	fight_results.append(fight_result)
	var selected_how_many_times: int = fight_results.size()
	_fight_decision_log[story_fight_decision] = fight_results
	decision_made.emit(story_fight_decision, selected_how_many_times)
	#if fight_result.get_save_outcome() != SaveResult.Outcome.FAILURE:
		#enter_page(story_fight_decision.transition.get_story_page())
	#else:
		#enter_page(story_fight_decision.failure_transition.get_story_page())
	#else:
	enter_page(current_story_book_page.story_page)

func get_how_often_decision_has_been_made(story_decision: StoryDecision) -> int:
	if story_decision is StorySaveDecision:
		if not _save_decision_log.has(story_decision): return 0
		var save_decision_results: Array[SaveResult] = _save_decision_log.get(story_decision)
		return save_decision_results.size()
	return _decision_log.get(story_decision, 0)

func get_how_often_page_has_been_entered(story_page: StoryPage) -> int:
	return _page_log.get(story_page, 0)

func _create_story_book_page(story_page: StoryPage) -> StoryBookPage:
	return StoryBookPage.new(
		story_page,
		story_page.get_page_title(self),
		story_page.get_description(self),
		story_page.get_background(self),
		story_page.get_ambience(self),
		story_page.get_decisions(self),
		story_page.get_events(self),
	)
