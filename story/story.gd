@tool
class_name Story
extends Node

signal story_book_page_entered(story_book_page: StoryBookPage)

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
		if current_story_book_page:
			for choice: StoryBookChoice in current_story_book_page.choices: choice.chosen.disconnect(_on_choice_made)
		_page_stack.push_back(current_story_book_page)
		current_story_book_page = story_book_page
		var page_log: Array[StoryBookPage] = _page_log.get_or_add(current_story_book_page.story_page, [] as Array[StoryBookPage])
		page_log.append(current_story_book_page)
		#for event: StoryPage in current_story_book_page.get_events(self): _page_log[event] = get_how_often_page_has_been_entered(event) + 1
		@warning_ignore("unsafe_method_access")
		Stage.enter_story_book_page(current_story_book_page)
		for choice: StoryBookChoice in current_story_book_page.choices: choice.chosen.connect(_on_choice_made.bind(choice))
		story_book_page_entered.emit(current_story_book_page)

var _current_dice_request: DiceRequest :
	set(new_dice_request):
		_current_dice_request = new_dice_request

var _page_stack: Array[StoryBookPage] = [ ]
# StoryBookPage -> Array[StoryBookPage]
var _page_log: Dictionary[StoryPage, Array] = { }
# StoryDecision -> StoryBookChoice (individual times the decision has been made)
var _decision_log: Dictionary[StoryDecision, Array] = { }

func start_adventure(new_adventure: Adventure, protagonist_profile: CharacterProfile) -> void:
	assert(new_adventure)
	assert(protagonist_profile)
	assert(protagonist_profile.is_valid())
	adventure = new_adventure
	protagonist = _party.create_character(protagonist_profile)
	enter_page(adventure.starting_page)

func enter_page(story_page: StoryPage) -> void:
	current_story_book_page = _create_story_book_page(story_page) if story_page else null

func request_save(save_request: SaveRequest) -> void:
	_current_dice_request = save_request

func get_requested_save() -> SaveRequest:
	if not _current_dice_request is SaveRequest: return null
	return _current_dice_request

func request_fight(fight_request: FightRequest) -> void:
	_current_dice_request = fight_request

func get_requested_fight() -> FightRequest:
	if not _current_dice_request is FightRequest: return null
	return _current_dice_request

func get_how_often_decision_has_been_made(story_decision: StoryDecision) -> int:
	if not _decision_log.has(story_decision): return 0
	return _decision_log[story_decision].size()

func get_how_often_page_has_been_entered(story_page: StoryPage) -> int:
	return _page_log.get(story_page, 0)

func _create_story_book_page(story_page: StoryPage) -> StoryBookPage:
	assert(protagonist)
	assert(story_page)
	return StoryBookPage.new(
		protagonist,
		story_page,
		story_page.get_page_title(self),
		story_page.get_description(self),
		story_page.get_background(self),
		story_page.get_ambience(self),
		story_page.get_decisions(self),
		story_page.get_events(self),
	)

func _on_choice_made(story_book_choice: StoryBookChoice) -> void:
	assert(story_book_choice)
	var story_decision: StoryDecision = story_book_choice.get_story_decision()
	if story_decision != StoryDecision.get_continue():
		var decision_log: Array[StoryBookChoice] = _decision_log.get_or_add(story_decision, [] as Array[StoryBookChoice])
		decision_log.append(story_book_choice) 
	enter_page(story_book_choice.get_transition())
