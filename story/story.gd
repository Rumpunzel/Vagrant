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

## The pending save against being knocked out and the choice to give in instead; either calls [member _after_incapacitation_save]
## (with the save's result, or null for giving in), which goes on with the exchange
var _incapacitation_save: StorySaveDecision
var _after_incapacitation_save: Callable
## Plain choices offered in the middle of an exchange -> what choosing them does instead of following a transition
var _pending_choices: Dictionary[StoryChoice, Callable] = {}
## Paragraphs of the exchange summary already shown on an earlier page (before an incapacitation save)
var _summary_start: int = 0

var _current_story_page: StoryPage:
	set(story_page):
		if story_page == null:
			var last_adventure_page: AdventurePage = _page_stack.pop_back()
			story_page = _create_story_page(last_adventure_page)
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
## The page on which an event's decision was last chosen; the pages behind the event keep it
var _host: AdventurePage
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

func get_protagonist() -> Character: return _protagonist

## The monster [param monster_profile] spawned by [param spawning_page] (spawned now if it wasn't yet); a generic event's at the current host
func get_monster(spawning_page: AdventurePage, monster_profile: MonsterProfile, index: int = 0) -> Monster:
	return _monsters.get_monster(spawning_page, monster_profile, index, _host if spawning_page.generic else null)

## The page the current event is shown on ([AdventureHostReference])
func get_host() -> AdventurePage: return _host

func get_how_often_decision_has_been_made(story_decision: AdventureDecision) -> int:
	if not _decision_log.has(story_decision): return 0
	return _decision_log[story_decision].size()

func get_how_often_page_has_been_entered(adventure_page: AdventurePage) -> int:
	var visited_story_pages: Array[StoryPage] = _page_log.get(adventure_page, [] as Array[StoryPage])
	return visited_story_pages.size()

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
	if decisions.is_empty(): decisions.append(AdventureDecision.get_turn_back())
	var story_choices: Array[StoryChoice] = []
	for decision: AdventureDecision in decisions:
		if decision is AdventureFightDecision:
			var fight: Fight = _create_fight(adventure_page, decision as AdventureFightDecision)
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
	return Fight.new(decision, _protagonist, get_monster(spawning_page, decision.enemies[0]), _protagonist)

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
	if _pending_choices.has(story_choice):
		var resume: Callable = _pending_choices[story_choice]
		_pending_choices.clear()
		resume.call()
		return
	var story_decision: AdventureDecision = story_choice.get_adventure_decision()
	var shown_on: AdventurePage = _current_story_page.adventure_page
	var owner: AdventurePage = shown_on.find_decision_owner(story_decision)
	if owner != null and owner != shown_on: _host = shown_on
	if story_decision != AdventureDecision.get_turn_back():
		var decision_log: Array[StoryChoice] = _decision_log.get_or_add(story_decision, [] as Array[StoryChoice])
		decision_log.append(story_choice)
	var consequences: Array[StoryConsequence] = story_choice.get_consequences()
	for consequence: StoryConsequence in consequences:
		# A lambda keeps the RefCounted consequence alive until the queue reaches it; a bound Callable does not
		_event_queue.queue_callable(func() -> void: consequence.resolve(self, 0))
	if not consequences.is_empty(): _event_queue.queue_delay(_reveal_delay)
	_event_queue.queue_callable(func() -> void: _follow(story_choice))

func _follow(story_choice: StoryChoice) -> void:
	_go(story_choice.get_transition_reference(), story_choice.get_adventure_decision().back_steps)

## Enters the page [param reference] leads to; none: goes back [param back_steps] pages; [AdventurePreviousLocationReference]: back to before the host
func _go(reference: AdventurePageReference, back_steps: int) -> void:
	if reference is AdventurePreviousLocationReference:
		var host_index: int = _page_stack.rfind(_host)
		if host_index > 0: back_steps = _page_stack.size() - host_index + 1
		# Nothing before the host (the adventure started there): back to the host
		elif host_index == 0: back_steps = _page_stack.size()
		else: back_steps = 1
	var transition: AdventurePage = _resolve(reference)
	if not transition:
		for _step: int in back_steps - 1: _page_stack.pop_back()
	enter_page(transition)

func _resolve(reference: AdventurePageReference) -> AdventurePage:
	return reference.resolve(self) if reference != null else null

func _on_dice_requested(dice_request: DiceRequest, _story_choice: StoryChoice) -> void:
	_current_dice_request = dice_request

func _on_roll_requested(dice_request: DiceRequest, story_choice: StoryChoice) -> void:
	assert(_current_dice_request == dice_request)
	var dice_result: DiceRequestResult = _current_dice_request.roll()
	assert(dice_result)
	assert(dice_result.get_dice_request() == _current_dice_request)
	if story_choice == _incapacitation_save:
		_current_dice_request = null
		_end_incapacitation_choice(dice_result as SaveResult)
		return
	_event_queue.queue_delay(_reveal_delay)
	if story_choice is StoryFightDecision:
		_resolve_fight(dice_result as FightResult, story_choice as StoryFightDecision)
		return
	_event_queue.queue_callable(func() -> void:
		_story_book.display_dice_result(dice_result)
		_story_book.display_dice_evaluation(dice_result)
	)
	_event_queue.queue_callable(func() -> void: dice_request.character.parse_dice_result(dice_result))
	_event_queue.queue_callable(_play_outcome_sound.bind(dice_result))
	_event_queue.queue_callable(func() -> void: _current_dice_request = null)
	_event_queue.queue_delay(_reveal_delay)
	var consequences: Array[StoryConsequence] = story_choice.get_consequences()
	for consequence: StoryConsequence in consequences:
		_event_queue.queue_callable(func() -> void: consequence.resolve(self, dice_result.get_margin()))
	if not consequences.is_empty(): _event_queue.queue_delay(_reveal_delay)
	_event_queue.queue_callable(func() -> void: _follow(story_choice))

func _resolve_fight(fight_result: FightResult, story_choice: StoryFightDecision) -> void:
	var fight: Fight = story_choice.fight
	_event_queue.queue_callable(func() -> void:
		fight.start_exchange_from(fight_result)
		_current_dice_request = null
		_summary_start = 0
		_play_fight_step(fight, fight_result, story_choice)
	)

## Applies and shows the next step of the exchange, then queues the pause after it and the step after that
func _play_fight_step(fight: Fight, fight_result: FightResult, story_choice: StoryFightDecision) -> void:
	if not fight.is_exchange_pending():
		_end_exchange(fight, fight_result, story_choice)
		return
	var step: ExchangeStep = fight.get_current_step()
	if step is CommitStep:
		_ask_to_commit(fight, step as CommitStep, fight_result, story_choice)
		return
	if step is ArmorStep and (step as ArmorStep).get_undecided_die(fight):
		_ask_for_armor(fight, step as ArmorStep, fight_result, story_choice)
		return
	if step is IncapacitationStep and step.is_player(fight):
		_ask_for_incapacitation_save(fight, step as IncapacitationStep, fight_result, story_choice)
		return
	var told: String = fight.advance()
	var pause: bool = not told.is_empty()
	# The dice log tells both threats with the player's dice, their colours come with what became of them
	if step is DiceStep and step.is_player(fight): _story_book.display_dice_result(fight_result)
	elif step is BreathDiceStep and step.is_player(fight):
		_story_book.display_dice_evaluation(fight_result)
		_play_outcome_sound(fight_result)
		pause = true
	# Injury sounds play when they are suffered
	elif step is InjuryStep:
		_story_book.show_injury(step.pick(fight, "You", step.get_actor(fight).get_actor_name()), step.get_side(fight).injury_taken)
		pause = true
	_reveal(fight, told, pause)
	_event_queue.queue_callable(func() -> void: _play_fight_step(fight, fight_result, story_choice))

func _end_exchange(fight: Fight, fight_result: FightResult, story_choice: StoryFightDecision) -> void:
	var told: String = fight.end_exchange()
	_reveal(fight, told, not told.is_empty())
	_event_queue.queue_callable(func() -> void:
		if fight.is_ongoing():
			_current_story_page = _create_fight_exchange_page(fight)
			return
		for consequence: StoryConsequence in story_choice.get_consequences(): consequence.resolve(self, fight_result.get_margin())
		_follow(story_choice)
	)

## Types the exchange summary if [param told] added to it and queues waiting for that, then the pause if [param pause]
func _reveal(fight: Fight, told: String, pause: bool) -> void:
	if not told.is_empty():
		_story_book.show_outcome(fight.get_exchange_summary(_summary_start))
		_event_queue.queue_until(_story_book.get_outcome_typed(), _story_book.is_outcome_typed)
	if pause: _event_queue.queue_delay(_reveal_delay)

## Shows the commit panel below the roll; the exchange goes on once the player strikes
func _ask_to_commit(fight: Fight, step: CommitStep, fight_result: FightResult, story_choice: StoryFightDecision) -> void:
	fight.advance()
	var panel: FightCommitPanel = FightCommitPanel.new()
	panel.setup(fight, step)
	panel.committed.connect(func(weapon_die: Die, raises_shield: bool) -> void:
		panel.queue_free()
		fight.resolve_player_choice(func(player: FightSide) -> void:
			if step.has_weapon_choice(fight):
				player.chosen_weapon_die = weapon_die
				player.holds_back = weapon_die == null
			if step.has_shield_choice(fight): player.shield_use = FightSide.ShieldUse.RAISE if raises_shield else FightSide.ShieldUse.LOWER
		)
		# The dice log shows the threats as committed
		fight_result.exchange = fight.get_last_exchange()
		_event_queue.queue_callable(func() -> void: _play_fight_step(fight, fight_result, story_choice))
	)
	_story_book.show_panel(panel)

## Asks, one page per blocked blow, which piece of armour takes it; the armour step and the rest of the exchange go on below the last one
func _ask_for_armor(fight: Fight, step: ArmorStep, fight_result: FightResult, story_choice: StoryFightDecision) -> void:
	var blocked_die: Die = step.get_undecided_die(fight)
	var resume: Callable = func(armor_pick: ArmorPick) -> void:
		fight.armor_picks[blocked_die] = armor_pick
		if step.get_undecided_die(fight):
			_event_queue.queue_callable(func() -> void: _ask_for_armor(fight, step, fight_result, story_choice))
			return
		# The rest of the exchange is told on the decision's page
		_summary_start = fight.get_paragraph_count()
		_event_queue.queue_callable(func() -> void: _play_fight_step(fight, fight_result, story_choice))
	var choices: Array[StoryChoice] = []
	for option: ArmorPick in ArmorPick.get_options(_protagonist.armor, blocked_die.result):
		choices.append(_create_pending_choice(_describe_armor_pick(option, blocked_die.result), resume.bind(option)))
	_show_fight_decision_page(fight, "Your armour catches %s %d." % [step.get_foe_owner(fight), blocked_die.result], choices)

func _describe_armor_pick(option: ArmorPick, result: int) -> String:
	var piece: String = option.piece.get_equipment_name()
	if option.ruin: return "Let your %s take it and be ruined." % piece
	if option.piece.is_marked(result): return "Let your %s take it: the next higher result gets marked." % piece
	return "Let your %s take it: the %d gets marked." % [piece, result]

func _create_pending_choice(description: String, on_chosen: Callable) -> StoryChoice:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.description = description
	var choice: StoryChoice = StoryChoice.from_adventure_decision(decision, _protagonist)
	_pending_choices[choice] = on_chosen
	return choice

## A page of the fight, on the same backdrop, with decisions taken in the middle of an exchange
func _show_fight_decision_page(fight: Fight, description: String, choices: Array[StoryChoice]) -> void:
	var page: StoryPage = StoryPage.new(
		_current_story_page.adventure_page,
		fight.get_title(),
		description,
		_current_story_page.background,
		_current_story_page.ambience,
		choices,
		[],
	)
	page.fight = fight
	_current_story_page = page

## Shows a page with a Guts save against all the player's injuries; the exchange goes on below it once the save is rolled
func _ask_for_incapacitation_save(fight: Fight, step: IncapacitationStep, fight_result: FightResult, story_choice: StoryFightDecision) -> void:
	var save_decision: AdventureSaveDecision = AdventureSaveDecision.new()
	save_decision.description = "Stay conscious!"
	save_decision.attribute = Rules.STRENGTH
	save_decision.difficulty = step.get_difficulty(fight)
	_incapacitation_save = StoryChoice.from_adventure_decision(save_decision, _protagonist) as StorySaveDecision
	var give_in: StoryChoice = _create_pending_choice("Give in.", func() -> void: _end_incapacitation_choice(null))
	_after_incapacitation_save = func(save_result: SaveResult) -> void:
		_event_queue.queue_delay(_reveal_delay)
		_event_queue.queue_callable(func() -> void: _resolve_incapacitation_save(fight, step, save_result, fight_result, story_choice))
	var description: String = "Your wounds (%s) pull you towards the dark. Your sight blurs, your knees give way — hold on to your senses!" % Injury.to_bbcode(step.get_difficulty(fight))
	_show_fight_decision_page(fight, description, [_incapacitation_save, give_in] as Array[StoryChoice])

func _end_incapacitation_choice(save_result: SaveResult) -> void:
	_incapacitation_save = null
	_pending_choices.clear()
	_after_incapacitation_save.call(save_result)

## [param save_result] is null when the player gave in: that fails the save without rolling
func _resolve_incapacitation_save(fight: Fight, step: IncapacitationStep, save_result: SaveResult, fight_result: FightResult, story_choice: StoryFightDecision) -> void:
	if save_result:
		_story_book.display_dice_result(save_result)
		_story_book.display_dice_evaluation(save_result)
		_protagonist.parse_dice_result(save_result)
		_play_outcome_sound(save_result)
	fight.advance()
	# The rest of the exchange is told on the save's page
	_summary_start = fight.get_paragraph_count()
	_reveal(fight, step.resolve(fight, save_result != null and save_result.is_success()), true)
	_event_queue.queue_callable(func() -> void: _play_fight_step(fight, fight_result, story_choice))

func _play_outcome_sound(dice_result: DiceRequestResult) -> void:
	if dice_result.is_success(): _success_audio_player.play()
	else: _failure_audio_player.play()

func _on_party_character_selected(character: Character) -> void:
	_protagonist = character
