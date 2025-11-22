@tool
class_name Story
extends Node

signal story_page_entered(story_page: StoryPage)
signal dice_requested(dice_request: DiceRequest)
signal save_rolled(save_result: SaveResult)
signal fight_rolled(fight_result: FightResult)

@export_range(0.0, 5.0) var _reveal_delay: float = 1.5

@export_group("Configuration")
@export var _update_delay_timer: Timer
@export var _success_audio_player: AudioStreamPlayer
@export var _failure_audio_player: AudioStreamPlayer
@export var _party: Party
@export var _title: TypingLabel

var adventure: Adventure:
	set(new_adventure):
		assert(not adventure or Engine.is_editor_hint())
		assert(new_adventure or Engine.is_editor_hint())
		adventure = new_adventure
		if not adventure: return
		_title.type_text(adventure.title)

var protagonist: Character :
	set(new_protagonist):
		assert(new_protagonist)
		protagonist = new_protagonist
		if not _current_dice_request: return
		_current_dice_request.character = protagonist

var current_story_page: StoryPage:
	set(story_page):
		if story_page == null:
			var last_adventure_page: AdventurePage = _page_stack.pop_back()
			story_page = _create_story_page(last_adventure_page)
		#elif current_page == story_page:
			#print_debug("Already on page: <%s>!" % current_page)
			#return
		if current_story_page:
			_page_stack.push_back(current_story_page.adventure_page)
			for choice: StoryChoice in current_story_page.choices:
				choice.chosen.disconnect(_on_choice_made)
				choice.dice_requested.disconnect(_on_dice_requested)
		current_story_page = story_page
		assert(current_story_page)
		var page_log: Array[StoryPage] = _page_log.get_or_add(current_story_page.adventure_page, [] as Array[StoryPage])
		page_log.append(current_story_page)
		#for event: AdventurePage in current_story_page.get_events(self): _page_log[event] = get_how_often_page_has_been_entered(event) + 1
		for choice: StoryChoice in current_story_page.choices:
			choice.chosen.connect(_on_choice_made.bind(choice))
			choice.dice_requested.connect(_on_dice_requested)
		story_page_entered.emit(current_story_page)

var _current_dice_request: DiceRequest :
	set(new_current_dice_request):
		if _current_dice_request:
			if _current_dice_request is SaveRequest: _current_dice_request.rolled.disconnect(_on_save_rolled)
			elif _current_dice_request is FightRequest: _current_dice_request.rolled.disconnect(_on_fight_rolled)
		_current_dice_request = new_current_dice_request
		dice_requested.emit(_current_dice_request)
		if not _current_dice_request: return
		_current_dice_request.character = protagonist
		if _current_dice_request is SaveRequest: _current_dice_request.rolled.connect(_on_save_rolled)
		elif _current_dice_request is FightRequest: _current_dice_request.rolled.connect(_on_fight_rolled)
		else: assert(false, "Not implemented!")

var _page_stack: Array[AdventurePage] = []
# StoryPage -> Array[StoryPage]
var _page_log: Dictionary[AdventurePage, Array] = {}
# AdventureDecision -> StoryChoice (individual times the decision has been made)
var _decision_log: Dictionary[AdventureDecision, Array] = {}

func start_adventure(new_adventure: Adventure, protagonist_profile: CharacterProfile) -> void:
	assert(new_adventure)
	assert(protagonist_profile)
	assert(protagonist_profile.is_valid())
	adventure = new_adventure
	protagonist = _party.create_character(protagonist_profile)
	enter_page(adventure.starting_page)

func enter_page(adventure_page: AdventurePage) -> void:
	current_story_page = _create_story_page(adventure_page) if adventure_page else null

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

func get_how_often_decision_has_been_made(story_decision: AdventureDecision) -> int:
	if not _decision_log.has(story_decision): return 0
	return _decision_log[story_decision].size()

func get_how_often_page_has_been_entered(adventure_page: AdventurePage) -> int:
	return _page_log.get(adventure_page, 0)

func _create_story_page(adventure_page: AdventurePage) -> StoryPage:
	assert(protagonist)
	assert(adventure_page)
	return StoryPage.new(
		func() -> Character: return protagonist,
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
	story_choice.resolve_consequences()
	enter_page(story_choice.get_transition())

func _on_dice_requested(dice_request: DiceRequest) -> void:
	_current_dice_request = dice_request

func _on_save_rolled(save_result: SaveResult) -> void:
	assert(save_result)
	assert(save_result.get_dice_request() == _current_dice_request)
	_current_dice_request = null
	save_rolled.emit(save_result)
	_update_delay_timer.start(_reveal_delay)
	await _update_delay_timer.timeout
	if save_result.is_success(): _success_audio_player.play()
	else: _failure_audio_player.play()

func _on_fight_rolled(fight_result: FightResult) -> void:
	assert(fight_result)
	assert(fight_result.get_dice_request() == _current_dice_request)
	_current_dice_request = null
	fight_rolled.emit(fight_result)

func _on_party_character_selected(character: Character) -> void:
	protagonist = character
