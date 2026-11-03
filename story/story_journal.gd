class_name StoryJournal
extends RefCounted

## What happened in a story, in order: each entry is written to the [GameLog] and kept (plain values and [ResourceId]s, for the save).
## Also counts how often each page was entered and each decision made, which conditions and texts ask for.

var entries: Array[Dictionary] = []

var _times_entered: Dictionary[AdventurePage, int] = {}
var _times_made: Dictionary[AdventureDecision, int] = {}
## Instance IDs of the actors [method watch_actor] already listens to
var _watched: Dictionary[int, bool] = {}

func get_times_entered(page: AdventurePage) -> int: return _times_entered.get(page, 0)
func get_times_made(decision: AdventureDecision) -> int: return _times_made.get(decision, 0)

func start(adventure: Adventure, random_seed: int) -> void:
	_write({type = "start", adventure = ResourceId.of(adventure), seed = random_seed}, "started %s, seed %d" % [describe(adventure), random_seed])

func enter(page: AdventurePage) -> void:
	_times_entered[page] = get_times_entered(page) + 1
	_write({type = "enter", page = ResourceId.of(page)}, "entered %s" % describe(page))

func choose(decision: AdventureDecision) -> void:
	_times_made[decision] = get_times_made(decision) + 1
	_write({type = "choose", decision = ResourceId.of(decision)}, "chose %s" % describe(decision))

func roll(result: DiceRequestResult) -> void:
	var request: DiceRequest = result.get_dice_request()
	var faces: Array[int] = []
	for die: Die in result.dice: faces.append(die.result)
	var attribute: String = request.attribute.resource_path.get_file().get_basename() if request.attribute != null else ""
	var outcome: String = DiceRequestResult.Outcome.find_key(result.get_outcome())
	_write(
		{type = "roll", decision = ResourceId.of(request.get_source()), attribute = attribute, dice = faces, outcome = outcome, margin = result.get_margin()},
		"rolled %s %s for %s: %s by %d" % [attribute, faces, describe(request.get_source()), outcome.to_lower(), result.get_margin()],
	)

func chance(condition: AdventureChanceCondition, came_up: bool) -> void:
	_write(
		{type = "chance", condition = ResourceId.of(condition), came_up = came_up},
		"chance %d in %d %s (%s)" % [condition.times, condition.out_of, "came up" if came_up else "did not come up", ResourceId.of(condition)],
	)

## The log line also tells what happened in it
func end_exchange(fight: Fight) -> void:
	var outcome: String = Fight.Outcome.find_key(fight.outcome)
	var told: String = ""
	for paragraph: String in fight.get_exchange_summary().split("[/p]", false): told += "
	" + _to_plain_text(paragraph)
	_write(
		{type = "exchange", fight = ResourceId.of(fight.decision), number = fight.get_exchange_count(), outcome = outcome},
		"exchange %d of %s vs %s: %s%s" % [fight.get_exchange_count(), fight.first.get_actor_name(), fight.second.get_actor_name(), outcome.to_lower(), told],
	)

## Writes what happens to [param actor]'s breath dice and injuries, and a character catching breath; once per actor
func watch_actor(actor: Actor) -> void:
	if _watched.has(actor.get_instance_id()): return
	_watched[actor.get_instance_id()] = true
	actor.suffered_injury.connect(_on_suffered_injury.bind(actor))
	actor.lost_breath.connect(_on_lost_breath.bind(actor))
	if actor is Character: (actor as Character).caught_breath.connect(_on_caught_breath.bind(actor))

## Writes the stage changes and moves of [param world]
func watch(world: StoryWorld) -> void:
	world.stage_set.connect(_on_stage_set)
	world.moved.connect(_on_moved)

func _on_stage_set(subject: Resource, track: String, stage: String) -> void:
	_write({type = "stage", subject = ResourceId.of(subject), track = track, stage = stage}, "%s: %s is now %s" % [describe(subject), track, stage])

func _on_moved(encounter: AdventureEncounter, places: Array[AdventureLocation]) -> void:
	var place_ids: Array[String] = []
	for place: AdventureLocation in places: place_ids.append(ResourceId.of(place))
	var names: Array[String] = []
	for place: AdventureLocation in places: names.append(describe(place))
	_write({type = "move", encounter = ResourceId.of(encounter), places = place_ids}, "%s moved to %s" % [describe(encounter), ", ".join(names)])

func _on_suffered_injury(injury: Injury, actor: Actor) -> void:
	_write(
		{type = "injury", actor = actor.get_actor_name(), magnitude = injury.magnitude, total = actor.get_injury_total()},
		"%s suffered an injury of %d (%d in all)" % [actor.get_actor_name(), injury.magnitude, actor.get_injury_total()],
	)

func _on_lost_breath(lost: Array[Die], actor: Actor) -> void:
	var dice: Array[String] = []
	for die: Die in lost: dice.append(str(die.die_type))
	_write(
		{type = "breath_lost", actor = actor.get_actor_name(), dice = dice, left = actor.get_breath_dice_count()},
		"%s lost %s breath (%d left)" % [actor.get_actor_name(), " ".join(dice), actor.get_breath_dice_count()],
	)

func _on_caught_breath(recovered: Dictionary, character: Character) -> void:
	var dice: Dictionary[String, int] = {}
	for die_type: DieType in recovered: dice[str(die_type)] = recovered[die_type]
	var exhausted: Array[String] = []
	for die_type: DieType in character.exhaustion: exhausted.append(str(die_type))
	_write(
		{type = "breath_caught", actor = character.get_actor_name(), recovered = dice, exhaustion = exhausted},
		"%s caught breath: recovered %s, exhausted %s" % [character.get_actor_name(), dice, " ".join(exhausted)],
	)

func _write(entry: Dictionary, line: String) -> void:
	entries.append(entry)
	GameLog.write("story", line)

## "Title" (id), for the log
static func describe(resource: Resource) -> String:
	if resource == null: return "nothing"
	var label: String = ""
	if resource is AdventurePage: label = (resource as AdventurePage).title
	elif resource is AdventureDecision: label = (resource as AdventureDecision).description
	var id: String = ResourceId.of(resource)
	var script: Script = resource.get_script()
	if label.is_empty(): return id if not id.is_empty() else "(unsaved %s)" % (script.get_global_name() if script != null else resource.get_class())
	return "\"%s\" (%s)" % [label, id] if not id.is_empty() else "\"%s\"" % label

## A loaded save's entries; the counts are rebuilt from them
func restore(saved: Array) -> void:
	entries.assign(saved)
	_times_entered.clear()
	_times_made.clear()
	for entry: Dictionary in entries:
		match entry.type:
			"enter":
				var page: AdventurePage = ResourceId.find(entry.page as String) as AdventurePage
				if page != null: _times_entered[page] = get_times_entered(page) + 1
			"choose":
				var decision: AdventureDecision = ResourceId.find(entry.decision as String) as AdventureDecision
				if decision != null: _times_made[decision] = get_times_made(decision) + 1

func load_run(run: String) -> void:
	_write({type = "load", run = run}, "loaded run %s" % run)

static func _to_plain_text(bbcode: String) -> String:
	var images: RegEx = RegEx.create_from_string("\\[img[^\\]]*\\].*?\\[/img\\]")
	var tags: RegEx = RegEx.create_from_string("\\[[^\\]]*\\]")
	return tags.sub(images.sub(bbcode, "", true), "", true).strip_edges()
