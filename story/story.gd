@tool
class_name Story
extends Node

signal story_page_entered(story_page: StoryPage)
signal dice_requested(dice_request: DiceRequest)

@export_range(0.0, 5.0) var _reveal_delay: float = 1.5

@export_group("Configuration")
@export var _event_queue: EventQueue
@export var _success_audio_player: AudioStreamPlayer
@export var _failure_audio_player: AudioStreamPlayer
@export var _party: Party
@export var _title: TypingLabel
@export var _story_book: StoryBook

var _adventure: Adventure:
	set(new_adventure):
		assert(not _adventure or Engine.is_editor_hint())
		assert(new_adventure or Engine.is_editor_hint())
		_adventure = new_adventure
		if not _adventure: return
		_title.type_text(_adventure.title)

var _protagonist: Character :
	set(new_protagonist):
		assert(new_protagonist)
		_protagonist = new_protagonist
		if _current_dice_request: _current_dice_request.character = _protagonist

var _current_story_page: StoryPage:
	set(story_page):
		if story_page == null:
			var last_adventure_page: AdventurePage = _page_stack.pop_back()
			story_page = _create_story_page(last_adventure_page)
		#elif current_page == story_page:
			#print_debug("Already on page: <%s>!" % current_page)
			#return
		if _current_story_page:
			_page_stack.push_back(_current_story_page.adventure_page)
			for choice: StoryChoice in _current_story_page.choices:
				choice.chosen.disconnect(_on_choice_made)
				choice.dice_requested.disconnect(_on_dice_requested)
				choice.roll_requested.disconnect(_on_roll_requested)
		_current_story_page = story_page
		assert(_current_story_page)
		var page_log: Array[StoryPage] = _page_log.get_or_add(_current_story_page.adventure_page, [] as Array[StoryPage])
		page_log.append(_current_story_page)
		#for event: AdventurePage in current_story_page.get_events(self): _page_log[event] = get_how_often_page_has_been_entered(event) + 1
		for choice: StoryChoice in _current_story_page.choices:
			choice.chosen.connect(_on_choice_made.bind(choice))
			choice.dice_requested.connect(_on_dice_requested.bind(choice))
			choice.roll_requested.connect(_on_roll_requested.bind(choice))
		_story_book.enter_story_page(_current_story_page)
		story_page_entered.emit(_current_story_page)

var _current_dice_request: DiceRequest :
	set(new_current_dice_request):
		_current_dice_request = new_current_dice_request
		if _current_dice_request: _current_dice_request.character = _protagonist
		dice_requested.emit(_current_dice_request)

var _page_stack: Array[AdventurePage] = []
# StoryPage -> Array[StoryPage]
var _page_log: Dictionary[AdventurePage, Array] = {}
# AdventureDecision -> StoryChoice (individual times the decision has been made)
var _decision_log: Dictionary[AdventureDecision, Array] = {}

func start_adventure(new_adventure: Adventure, protagonist_profile: CharacterProfile) -> void:
	assert(new_adventure)
	assert(protagonist_profile)
	assert(protagonist_profile.is_valid())
	_adventure = new_adventure
	_protagonist = _party.create_character(protagonist_profile)
	enter_page(_adventure.starting_page)

func enter_page(adventure_page: AdventurePage) -> void:
	_current_story_page = _create_story_page(adventure_page) if adventure_page else null

func get_how_often_decision_has_been_made(story_decision: AdventureDecision) -> int:
	if not _decision_log.has(story_decision): return 0
	return _decision_log[story_decision].size()

func get_how_often_page_has_been_entered(adventure_page: AdventurePage) -> int:
	return _page_log.get(adventure_page, 0)

func _create_story_page(adventure_page: AdventurePage) -> StoryPage:
	assert(_protagonist)
	assert(adventure_page)
	return StoryPage.new(
		_protagonist,
		adventure_page,
		adventure_page.get_page_title(self),
		adventure_page.get_description(self),
		adventure_page.get_background(self),
		adventure_page.get_ambience(self),
		adventure_page.get_decisions(self),
		adventure_page.get_events(self),
	)

func _on_choice_made(story_choice: StoryChoice) -> void:
	assert(story_choice)
	var story_decision: AdventureDecision = story_choice.get_adventure_decision()
	if story_decision != AdventureDecision.get_continue():
		var decision_log: Array[StoryChoice] = _decision_log.get_or_add(story_decision, [] as Array[StoryChoice])
		decision_log.append(story_choice)
	var consequences: Array[StoryConsequence] = story_choice.get_consequences()
	for consequence: StoryConsequence in consequences:
		_event_queue.queue_callable(consequence.resolve.bind(_protagonist, 0))
	if not consequences.is_empty(): _event_queue.queue_delay(_reveal_delay)
	_event_queue.queue_callable(func() -> void: enter_page(story_choice.get_transition()))

func _on_dice_requested(dice_request: DiceRequest, _story_choice: StoryChoice) -> void:
	_current_dice_request = dice_request

func _on_roll_requested(dice_request: DiceRequest, story_choice: StoryChoice) -> void:
	assert(_current_dice_request == dice_request)
	var dice_result: DiceRequestResult = _current_dice_request.roll()
	assert(dice_result)
	assert(dice_result.get_dice_request() == _current_dice_request)
	_event_queue.queue_delay(_reveal_delay)
	_event_queue.queue_callable(func() -> void: _story_book.display_dice_result(dice_result))
	#_event_queue.queue_callable(func() -> void: _party.display_dice_result(dice_result))
	_event_queue.queue_callable(func() -> void: if dice_result.is_success(): _success_audio_player.play() else: _failure_audio_player.play())
	_event_queue.queue_callable(func() -> void: _current_dice_request = null)
	_event_queue.queue_delay(_reveal_delay)
	var consequences: Array[StoryConsequence] = story_choice.get_consequences()
	for consequence: StoryConsequence in consequences:
		_event_queue.queue_callable(func() -> void: consequence.resolve(_protagonist, dice_result.get_margin()))
	if not consequences.is_empty(): _event_queue.queue_delay(_reveal_delay)
	_event_queue.queue_callable(func() -> void: enter_page(story_choice.get_transition()))

func _on_party_character_selected(character: Character) -> void:
	_protagonist = character
