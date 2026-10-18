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
@export var _monsters: Monsters
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
			if not _current_story_page.is_fight_exchange(): _page_stack.push_back(_current_story_page.adventure_page)
			for choice: StoryChoice in _current_story_page.choices:
				choice.chosen.disconnect(_on_choice_made)
				choice.dice_requested.disconnect(_on_dice_requested)
				choice.roll_requested.disconnect(_on_roll_requested)
		_current_story_page = story_page
		assert(_current_story_page)
		if not _current_story_page.is_fight_exchange():
			var page_log: Array[StoryPage] = _page_log.get_or_add(_current_story_page.adventure_page, [] as Array[StoryPage])
			page_log.append(_current_story_page)
		#for event: AdventurePage in current_story_page.get_events(self): _page_log[event] = get_how_often_page_has_been_entered(event) + 1
		for choice: StoryChoice in _current_story_page.choices:
			choice.chosen.connect(_on_choice_made.bind(choice))
			choice.dice_requested.connect(_on_dice_requested.bind(choice))
			choice.roll_requested.connect(_on_roll_requested.bind(choice))
		# Pages decided on arrival (e.g. a fight without breath) are skipped straight to their outcome.
		# Deferred, since choosing enters the next page, which would re-enter this setter.
		if _current_story_page.forced_choice:
			_current_story_page.forced_choice.chose.call_deferred()
			return
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
	return _page_log.get(adventure_page, [] as Array[StoryPage]).size()

func _create_story_page(adventure_page: AdventurePage) -> StoryPage:
	assert(_protagonist)
	assert(adventure_page)
	var forced_choices: Array[StoryChoice] = []
	var story_page: StoryPage = StoryPage.new(
		adventure_page,
		adventure_page.get_page_title(self),
		adventure_page.get_description(self),
		adventure_page.get_background(self),
		adventure_page.get_ambience(self),
		_create_story_choices(adventure_page, adventure_page.get_decisions(self), forced_choices),
		adventure_page.get_events(self),
	)
	if not forced_choices.is_empty(): story_page.forced_choice = forced_choices.front()
	return story_page

## Choices that must be taken right away (fights lost on arrival) are also added to [param forced_choices]
func _create_story_choices(adventure_page: AdventurePage, decisions: Array[AdventureDecision], forced_choices: Array[StoryChoice]) -> Array[StoryChoice]:
	if decisions.is_empty(): decisions.append(AdventureDecision.get_continue())
	var story_choices: Array[StoryChoice] = []
	for decision: AdventureDecision in decisions:
		if decision is AdventureFightDecision:
			var fight: Fight = _create_fight(adventure_page, decision)
			if fight.is_ongoing(): story_choices.append_array(_create_fight_choices(fight))
			else:
				var lost_choice: StoryChoice = StoryChoice.from_adventure_decision(_create_lost_fight_decision(fight), _protagonist)
				story_choices.append(lost_choice)
				forced_choices.append(lost_choice)
		else: story_choices.append(StoryChoice.from_adventure_decision(decision, _protagonist))
	return story_choices

func _create_fight(adventure_page: AdventurePage, decision: AdventureFightDecision) -> Fight:
	assert(not decision.enemies.is_empty(), "Fight decision \"%s\" has no enemies" % decision.description)
	# The monster belongs to the page (or event) that defines the fight, not the page it is shown on
	var spawning_page: AdventurePage = adventure_page.find_decision_owner(decision)
	if not spawning_page: spawning_page = adventure_page
	return Fight.new(decision, _protagonist, _monsters.get_monster(spawning_page, decision.enemies[0]))

## A fight already lost on arrival (no breath dice to resist with) only offers its failure path
func _create_lost_fight_decision(fight: Fight) -> AdventureDecision:
	assert(fight.outcome == Fight.Outcome.LOST)
	var lost_decision: AdventureDecision = AdventureDecision.new()
	lost_decision.description = "You can no longer resist."
	lost_decision.transition = fight.decision.failure_transition
	lost_decision.consequences = fight.decision.failure_consequences
	return lost_decision

func _create_fight_choices(fight: Fight) -> Array[StoryChoice]:
	return [StoryFightDecision.new(fight, false), StoryFightDecision.new(fight, true)]

## The next exchange of an ongoing fight, shown on the same backdrop as the page the fight started on
func _create_fight_exchange_page(fight: Fight) -> StoryPage:
	var from_page: StoryPage = _current_story_page
	var story_page: StoryPage = StoryPage.new(
		from_page.adventure_page,
		fight.get_title(),
		# What happened is shown below the previous roll; the monster's threat in the dice selection
		fight.get_condition_description(),
		from_page.background,
		from_page.ambience,
		_create_fight_choices(fight),
		[],
	)
	story_page.fight = fight
	return story_page

func _on_choice_made(story_choice: StoryChoice) -> void:
	assert(story_choice)
	var story_decision: AdventureDecision = story_choice.get_adventure_decision()
	if story_decision != AdventureDecision.get_continue():
		var decision_log: Array[StoryChoice] = _decision_log.get_or_add(story_decision, [] as Array[StoryChoice])
		decision_log.append(story_choice)
	var consequences: Array[StoryConsequence] = story_choice.get_consequences()
	for consequence: StoryConsequence in consequences:
		# A lambda keeps the RefCounted consequence alive until the queue reaches it; a bound Callable does not
		_event_queue.queue_callable(func() -> void: consequence.resolve(_protagonist, 0))
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
	if story_choice is StoryFightDecision:
		_resolve_fight(dice_result as FightResult, story_choice as StoryFightDecision)
		return
	#_event_queue.queue_callable(func() -> void: _party.display_dice_result(dice_result))
	_event_queue.queue_callable(func() -> void: dice_request.character.parse_dice_result(dice_result))
	_event_queue.queue_callable(func() -> void: if dice_result.is_success(): _success_audio_player.play() else: _failure_audio_player.play())
	_event_queue.queue_callable(func() -> void: _current_dice_request = null)
	_event_queue.queue_delay(_reveal_delay)
	var consequences: Array[StoryConsequence] = story_choice.get_consequences()
	for consequence: StoryConsequence in consequences:
		_event_queue.queue_callable(func() -> void: consequence.resolve(_protagonist, dice_result.get_margin()))
	if not consequences.is_empty(): _event_queue.queue_delay(_reveal_delay)
	_event_queue.queue_callable(func() -> void: enter_page(story_choice.get_transition()))

## Applies the exchange to both sides, then shows the next exchange or leaves the fight
func _resolve_fight(fight_result: FightResult, story_choice: StoryFightDecision) -> void:
	var fight: Fight = story_choice.fight
	# Injuries appear together with their sounds, which play when they are suffered
	_event_queue.queue_callable(func() -> void:
		fight.resolve(fight_result)
		var exchange: FightExchange = fight.get_last_exchange()
		if exchange.first.injury_taken > 0: _story_book.show_injury("You", exchange.first.injury_taken)
		if exchange.second.injury_taken > 0: _story_book.show_injury(fight.monster.get_monster_name(), exchange.second.injury_taken)
	)
	_event_queue.queue_callable(func() -> void: if fight_result.is_success(): _success_audio_player.play() else: _failure_audio_player.play())
	_event_queue.queue_callable(func() -> void: _current_dice_request = null)
	_event_queue.queue_delay(_reveal_delay)
	_event_queue.queue_callable(func() -> void: await _story_book.show_outcome(fight.get_exchange_summary()))
	_event_queue.queue_delay(_reveal_delay)
	_event_queue.queue_callable(func() -> void:
		if fight.is_ongoing():
			_current_story_page = _create_fight_exchange_page(fight)
			return
		for consequence: StoryConsequence in story_choice.get_consequences(): consequence.resolve(_protagonist, fight_result.get_margin())
		enter_page(story_choice.get_transition())
	)

func _on_party_character_selected(character: Character) -> void:
	_protagonist = character
