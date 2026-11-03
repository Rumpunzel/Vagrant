class_name StoryJournal
extends RefCounted

## What happened in a story, in order: each entry is written to the [GameLog] and kept (plain values and [ResourceId]s, for the save).
## Also counts how often each page was entered and each decision made, which conditions and texts ask for.

var entries: Array[Dictionary] = []

var _times_entered: Dictionary[AdventurePage, int] = {}
var _times_made: Dictionary[AdventureDecision, int] = {}

func get_times_entered(page: AdventurePage) -> int: return _times_entered.get(page, 0)
func get_times_made(decision: AdventureDecision) -> int: return _times_made.get(decision, 0)

func start(adventure: Adventure, random_seed: int) -> void:
	_write({type = "start", adventure = ResourceId.of(adventure), seed = random_seed}, "started %s, seed %d" % [_name(adventure), random_seed])

func enter(page: AdventurePage) -> void:
	_times_entered[page] = get_times_entered(page) + 1
	_write({type = "enter", page = ResourceId.of(page)}, "entered %s" % _name(page))

func choose(decision: AdventureDecision) -> void:
	_times_made[decision] = get_times_made(decision) + 1
	_write({type = "choose", decision = ResourceId.of(decision)}, "chose %s" % _name(decision))

func roll(result: DiceRequestResult) -> void:
	var request: DiceRequest = result.get_dice_request()
	var faces: Array[int] = []
	for die: Die in result.dice: faces.append(die.result)
	var attribute: String = request.attribute.resource_path.get_file().get_basename() if request.attribute != null else ""
	var outcome: String = DiceRequestResult.Outcome.find_key(result.get_outcome())
	_write(
		{type = "roll", decision = ResourceId.of(request.get_source()), attribute = attribute, dice = faces, outcome = outcome, margin = result.get_margin()},
		"rolled %s %s for %s: %s by %d" % [attribute, faces, _name(request.get_source()), outcome.to_lower(), result.get_margin()],
	)

func chance(condition: AdventureChanceCondition, came_up: bool) -> void:
	_write(
		{type = "chance", condition = ResourceId.of(condition), came_up = came_up},
		"chance %d in %d %s (%s)" % [condition.times, condition.out_of, "came up" if came_up else "did not come up", ResourceId.of(condition)],
	)

func end_exchange(fight: Fight) -> void:
	var outcome: String = Fight.Outcome.find_key(fight.outcome)
	_write(
		{type = "exchange", fight = ResourceId.of(fight.decision), number = fight.get_exchange_count(), outcome = outcome},
		"exchange %d of %s vs %s: %s" % [fight.get_exchange_count(), fight.first.get_actor_name(), fight.second.get_actor_name(), outcome.to_lower()],
	)

## Writes the stage changes and moves of [param world]
func watch(world: StoryWorld) -> void:
	world.stage_set.connect(_on_stage_set)
	world.moved.connect(_on_moved)

func _on_stage_set(subject: Resource, track: String, stage: String) -> void:
	_write({type = "stage", subject = ResourceId.of(subject), track = track, stage = stage}, "%s: %s is now %s" % [_name(subject), track, stage])

func _on_moved(encounter: AdventureEncounter, places: Array[AdventureLocation]) -> void:
	var place_ids: Array[String] = []
	for place: AdventureLocation in places: place_ids.append(ResourceId.of(place))
	var names: Array[String] = []
	for place: AdventureLocation in places: names.append(_name(place))
	_write({type = "move", encounter = ResourceId.of(encounter), places = place_ids}, "%s moved to %s" % [_name(encounter), ", ".join(names)])

func _write(entry: Dictionary, line: String) -> void:
	entries.append(entry)
	GameLog.write("story", line)

## "Title" (id) for the log
static func _name(resource: Resource) -> String:
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
