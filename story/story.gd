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

## What happened so far, in order; how often pages were entered and decisions made
var journal: StoryJournal = StoryJournal.new()
## Where the story stands (stages, where encounters are)
var world: StoryWorld:
	set(new_world):
		world = new_world
		journal.watch(world)
## The save slot autosaved to whenever the story can be saved ([SaveGame]); none: not saved (tests, unless they set one)
var run: String = ""
## Rolls a chance; tests put a fixed result in
var chance_roller: Callable = func(condition: AdventureChanceCondition) -> bool: return GameRandom.chance(condition.times, condition.out_of)

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
			journal.enter(_current_story_page.adventure_page)
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
		# Deferred: the event entering the page is still running
		_autosave.call_deferred()

var _current_dice_request: DiceRequest :
	set(new_current_dice_request):
		_current_dice_request = new_current_dice_request
		if _current_dice_request: _current_dice_request.character = _protagonist
		dice_requested.emit(_current_dice_request)

var _page_stack: Array[AdventurePage] = []
## The page on which an event's decision was last chosen; the pages behind the event keep it
var _host: AdventurePage
## The last location entered: "here"
var _location: AdventureLocation
## The encounter of the event one is in (also on the pages behind it); none at a location's own decisions
var _encounter: AdventureEncounter
## Chance conditions' rolls for the current arrival at a location ([AdventureChanceCondition])
var _chance_rolls: Dictionary[AdventureChanceCondition, bool] = {}
## The area just entered on arriving at the current location (from another area, or at the start), else none; the first time there or not
var _entered_area: AdventureArea
var _first_time_in_area: bool = false
var _areas_been_in: Array[AdventureArea] = [ ]
## Played from in the adventure editor ([AdventurePlayFrom]): on the first arrival its conditions count as met ([method is_forced])
var _forced: AdventureEvent
var _arrivals_while_forced: int = 0

func _init() -> void: world = StoryWorld.new()

## Goes on with a saved run ([method get_save]) of [param new_adventure], on the page it was saved on; the adventure must have
## everything the save names ([method SaveGame.get_problems])
func restore(new_adventure: Adventure, of_run: String, data: Dictionary) -> void:
	assert(new_adventure)
	_adventure = new_adventure
	run = of_run
	world = StoryWorld.new(new_adventure.encounters)
	var saved_world: Dictionary = data.world
	world.restore(saved_world)
	var protagonist_profile: CharacterProfile = new_adventure.protagonist.duplicate(true)
	var protagonist_data: Dictionary = data.protagonist
	var saved_profile: Dictionary = protagonist_data.profile
	Character.restore_profile(protagonist_profile, saved_profile)
	_protagonist = _party.create_character(protagonist_profile)
	_protagonist.restore(protagonist_data)
	journal.watch_actor(_protagonist)
	var saved_monsters: Array = data.monsters
	_monsters.restore(saved_monsters)
	_page_stack.assign(ResourceId.find_each_at(data, "page_stack"))
	_host = ResourceId.find_at(data, "host") as AdventurePage
	_location = ResourceId.find_at(data, "location") as AdventureLocation
	_encounter = ResourceId.find_at(data, "encounter") as AdventureEncounter
	_entered_area = ResourceId.find_at(data, "entered_area") as AdventureArea
	_first_time_in_area = data.first_time_in_area
	_areas_been_in.assign(ResourceId.find_each_at(data, "areas_been_in"))
	var chances: Dictionary = data.chance_rolls
	for id: String in chances: _chance_rolls[ResourceId.find(id) as AdventureChanceCondition] = chances[id]
	_forced = ResourceId.find_at(data, "forced") as AdventureEvent
	_arrivals_while_forced = data.arrivals_while_forced
	var random: Dictionary = data.random
	var random_seed: String = random.seed
	var random_state: String = random.state
	GameRandom.start(random_seed.to_int())
	GameRandom.set_state(random_state.to_int())
	# The page is entered again (its texts as on arriving there), so its arrival is taken out of the journal
	var entries: Array = data.journal
	var page: AdventurePage = ResourceId.find_at(data, "page") as AdventurePage
	var last: Dictionary = entries.back() if not entries.is_empty() else {}
	if last.get("type") == "enter" and last.get("page") == data.page: entries = entries.slice(0, -1)
	journal.restore(entries)
	journal.load_run(of_run)
	var book: Array = data.get("book", [])
	if _story_book != null: _story_book.restore(book)
	_current_story_page = _create_story_page(page)

func _autosave() -> void:
	if run.is_empty() or not can_save(): return
	var error: Error = SaveGame.capture(run, self).write()
	if error != OK: push_error("Autosave of %s failed: %s" % [run, error_string(error)])

## [param page]: start there instead of the starting page; [param host]: the page its event is on, entered first so going back and host links work
## [param forced]: an event played from in the adventure editor, shown on the first arrival whatever its conditions
func start_adventure(new_adventure: Adventure, protagonist_profile: CharacterProfile, page: AdventurePage = null, host: AdventurePage = null, forced: AdventureEvent = null) -> void:
	assert(new_adventure)
	assert(protagonist_profile)
	assert(protagonist_profile.is_valid())
	_adventure = new_adventure
	GameRandom.start()
	journal.start(new_adventure, GameRandom.get_seed())
	world = StoryWorld.new(new_adventure.encounters)
	_protagonist = _party.create_character(protagonist_profile)
	journal.watch_actor(_protagonist)
	_forced = forced
	if host != null and host != page:
		enter_page(host)
		_host = host
	enter_page(page if page != null else _adventure.starting_page)

func enter_page(adventure_page: AdventurePage) -> void:
	if adventure_page is AdventureLocation:
		var area: AdventureArea = (adventure_page as AdventureLocation).area
		_entered_area = area if area != null and (_location == null or _location.area != area) else null
		_first_time_in_area = _entered_area != null and not _areas_been_in.has(area)
		if _first_time_in_area: _areas_been_in.append(area)
		_location = adventure_page as AdventureLocation
		_chance_rolls.clear()
		_arrivals_while_forced += 1
		if _arrivals_while_forced > 1: _forced = null
	_current_story_page = _create_story_page(adventure_page) if adventure_page else null

func get_location() -> AdventureLocation: return _location

## The text of the area just entered on arriving at [param location] ([member AdventureArea.description], its first-time text the first time),
## as a paragraph; empty if no area was entered
func get_area_text(location: AdventureLocation) -> String:
	if _entered_area == null or location.area != _entered_area: return ""
	var first: bool = _first_time_in_area and not _entered_area.first_description.is_empty()
	var text: String = _entered_area.first_description if first else _entered_area.description
	return "[p]%s[/p]" % text if not text.is_empty() else ""

## The event played from in the adventure editor, or a scenario holding it, until the player arrives at a location the second time
func is_forced(event: AdventureEvent) -> bool:
	if _forced == null or event == null: return false
	return event == _forced or event is AdventureEventScenario and (event as AdventureEventScenario).get_listed_events().has(_forced)

## Whether [param condition]'s chance came up on this arrival at the location: rolled the first time it is asked, then kept until the next arrival
func roll_chance(condition: AdventureChanceCondition) -> bool:
	if not _chance_rolls.has(condition):
		_chance_rolls[condition] = chance_roller.call(condition)
		journal.chance(condition, _chance_rolls[condition])
	return _chance_rolls[condition]

## The encounter or location [param path] (a UID) names; empty: the encounter of [param event] (none given: of the event one is in), else the
## current location
func get_subject(path: String, event: AdventurePage = null) -> Resource:
	if not path.is_empty(): return Files.load_existing(path)
	var encounter: AdventureEncounter = world.get_encounter_of(event as AdventureEvent) if event is AdventureEvent else _encounter
	if encounter != null: return encounter
	return _location

func get_protagonist() -> Character: return _protagonist

## The monster of [param holder]: an encounter's, the same for the whole story; a one-off fight's (owned by its page), one per location
func get_monster(holder: AdventurePage, monster_profile: MonsterProfile) -> Monster:
	var monster: Monster = _monsters.get_monster(holder, monster_profile, 0, null if holder is AdventureEncounter else _location)
	journal.watch_actor(monster)
	return monster

## The page the current event is shown on ([AdventureHostReference])
func get_host() -> AdventurePage: return _host

func get_how_often_decision_has_been_made(story_decision: AdventureDecision) -> int: return journal.get_times_made(story_decision)
func get_how_often_page_has_been_entered(adventure_page: AdventurePage) -> int: return journal.get_times_entered(adventure_page)

## On a page with nothing going on: no fight under way, nothing queued, no decision in the middle of an exchange
func can_save() -> bool:
	if _current_story_page == null or _current_story_page.is_fight_exchange(): return false
	return _event_queue.is_idle() and _pending_choices.is_empty() and _incapacitation_save == null

## Everything a run needs to go on, as plain values and [ResourceId]s ([SaveGame]); random numbers' seed and state as text (JSON
## numbers are floats). Only a save from when it [method can_save] can be loaded; the debug panel shows it any time.
func get_save() -> Dictionary:
	var chances: Dictionary[String, bool] = {}
	for condition: AdventureChanceCondition in _chance_rolls: chances[ResourceId.of(condition)] = _chance_rolls[condition]
	return {
		adventure = ResourceId.of(_adventure),
		random = {seed = str(GameRandom.get_seed()), state = str(GameRandom.get_state())},
		journal = journal.entries.duplicate(true),
		world = world.get_save(),
		protagonist = _protagonist.get_save(),
		monsters = _monsters.get_save(),
		book = _story_book.get_save() if _story_book != null else [],
		page = ResourceId.of(_current_story_page.adventure_page),
		page_stack = ResourceId.of_each(_page_stack),
		host = ResourceId.of(_host),
		location = ResourceId.of(_location),
		encounter = ResourceId.of(_encounter),
		entered_area = ResourceId.of(_entered_area),
		first_time_in_area = _first_time_in_area,
		areas_been_in = ResourceId.of_each(_areas_been_in),
		chance_rolls = chances,
		forced = ResourceId.of(_forced),
		arrivals_while_forced = _arrivals_while_forced,
	}

func _create_story_page(adventure_page: AdventurePage) -> StoryPage:
	assert(_protagonist)
	assert(adventure_page)
	var choices: Array[StoryChoice] = _create_story_choices(adventure_page, adventure_page.get_decisions(self))
	# Nothing to choose (only dice decisions, no breath dice left): the first one fails right away
	var failed: StoryChoice = null
	if not choices.any(func(choice: StoryChoice) -> bool: return choice.is_available()):
		var first: StoryChoice = choices.front()
		failed = StoryChoice.from_adventure_decision(_create_failed_decision(first.get_adventure_decision() as AdventureDiceDecision), _protagonist)
		choices = [failed]
	var story_page: StoryPage = StoryPage.new(
		adventure_page,
		adventure_page.get_page_title(self),
		adventure_page.get_description(self),
		adventure_page.get_background(self),
		adventure_page.get_ambience(self),
		choices,
		adventure_page.get_events(self),
	)
	story_page.forced_choice = failed
	story_page.forbids_rest = adventure_page.forbids_rest(self)
	return story_page

func _create_story_choices(adventure_page: AdventurePage, decisions: Array[AdventureDecision]) -> Array[StoryChoice]:
	if decisions.is_empty(): decisions.append(AdventureDecision.get_turn_back())
	var story_choices: Array[StoryChoice] = []
	for decision: AdventureDecision in decisions:
		if decision is AdventureFightDecision: story_choices.append_array(_create_fight_choices(_create_fight(adventure_page, decision as AdventureFightDecision)))
		else:
			var choice: StoryChoice = StoryChoice.from_adventure_decision(decision, _protagonist)
			choice.description = decision.get_description(self)
			story_choices.append(choice)
	return story_choices

## Against the monster of its encounter (named, or the one of the event it is in), else a one-off fight against its first enemy
func _create_fight(adventure_page: AdventurePage, decision: AdventureFightDecision) -> Fight:
	var holder: AdventurePage = _find_decision_owner(adventure_page, decision)
	if holder == null: holder = adventure_page
	var encounter: AdventureEncounter = get_subject(decision.encounter, holder) as AdventureEncounter
	if encounter != null and encounter.profile is MonsterProfile:
		return Fight.new(decision, _protagonist, get_monster(encounter, encounter.profile as MonsterProfile), _protagonist)
	assert(not decision.enemies.is_empty(), "Fight decision \"%s\" has no monster encounter and no enemies" % decision.description)
	return Fight.new(decision, _protagonist, get_monster(holder, decision.enemies[0]), _protagonist)

## The page (it, or one of the events shown on it) that defines [param decision]
func _find_decision_owner(page: AdventurePage, decision: AdventureDecision) -> AdventurePage:
	if page.decisions.has(decision): return page
	for event: AdventureEvent in page.get_events(self):
		var holder: AdventurePage = event.find_decision_owner(decision)
		if holder != null: return holder
	return null

## A save or fight failed without rolling (no breath dice to roll): its failure path
func _create_failed_decision(decision: AdventureDiceDecision) -> AdventureDecision:
	var failed_decision: AdventureDecision = AdventureDecision.new()
	failed_decision.description = "You can no longer resist." if decision is AdventureFightDecision else "You are out of breath."
	failed_decision.transition = decision.failure_transition
	failed_decision.consequences = decision.failure_consequences
	return failed_decision

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
	var holder: AdventurePage = _find_decision_owner(shown_on, story_decision)
	if holder != null and holder != shown_on: _host = shown_on
	if holder is AdventureEvent: _encounter = world.get_encounter_of(holder as AdventureEvent)
	elif holder is AdventureLocation: _encounter = null
	if story_decision != AdventureDecision.get_turn_back(): journal.choose(story_decision)
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
	# Fight rolls are told by their exchange
	if not dice_result is FightResult: journal.roll(dice_result)
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
	journal.end_exchange(fight)
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
		_story_book.show_pick(_describe_commit(fight, step, weapon_die, raises_shield))
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

## What was committed to on the panel ([method _ask_to_commit]), for the page to keep in its place
func _describe_commit(fight: Fight, step: CommitStep, weapon_die: Die, raises_shield: bool) -> String:
	var picks: Array[String] = []
	if step.has_weapon_choice(fight): picks.append("You strike with your %s (%d)." % [weapon_die.die_type, weapon_die.result] if weapon_die != null else "You hold back.")
	if step.has_shield_choice(fight): picks.append("You raise your shield." if raises_shield else "You keep your shield down.")
	return " ".join(picks)

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
