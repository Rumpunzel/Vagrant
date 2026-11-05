@tool
class_name AdventureFightOdds
extends Node

## How the Fight Lab's reference fighters ([constant REFERENCE]: weak, average, strong) fare against the monster of each fight of an adventure.
## Simulated on demand ([method simulate]) in the lab's own process ([FightLabProcess]) and kept per adventure in [constant DIRECTORY] for
## next time. A monster whose file changed since, or changed reference fighters, make the odds out of date until simulated again.
## The lab assumes full breath dice and a fresh monster, and the reference scenario's strategies.

## Odds arrived, or a run started or failed
signal changed
signal progressed(done: int, total: int)

const REFERENCE: String = "uid://dr3ikpueok78u"  # reference.tres
const FIGHTS: int = 200
const MAX_EXCHANGES: int = 50
const DIRECTORY: String = "user://fight_lab/adventures/"
## Marks the stamps of the reference scenario and fighters
const REFERENCE_MARK: String = "reference:"
## Where the Fight Lab plugin puts itself in [Engine]'s meta ([code]fight_lab_plugin.gd[/code]'s META)
const LAB_META: StringName = &"fight_lab"

var failed: bool = false

var _runner: FightLabProcess
## The adventure's UID text, naming its files
var _key: String = ""
## The last result ([method FightLabRun.execute]) with what went into it: "monsters" (keys in side B's order), "stamps" (file → modified time)
var _result: Dictionary = {}
var _pending: Dictionary = {}
var _monster_of: Dictionary[AdventureFightDecision, MonsterProfile] = {}

func _init() -> void:
	_runner = FightLabProcess.new()
	_runner.progressed.connect(func(done: int, total: int) -> void: progressed.emit(done, total))
	_runner.finished.connect(_on_finished)
	add_child(_runner)

## Finds each fight's monster in [param graph], and the adventure's last odds if it is another one
func index(adventure: Adventure, graph: AdventureGraph) -> void:
	_monster_of = find_monsters(graph)
	var key: String = _key_of(adventure)
	if key == _key: return
	_key = key
	_result = {}
	failed = false
	if key.is_empty() or not FileAccess.file_exists(_file(".json")): return
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(_file(".json")))
	if saved is Dictionary and (saved as Dictionary).has("monsters"): _result = saved

## The fights of locations and events and the monster each fights
static func find_monsters(graph: AdventureGraph) -> Dictionary[AdventureFightDecision, MonsterProfile]:
	var found: Dictionary[AdventureFightDecision, MonsterProfile] = {}
	for page: AdventurePage in graph.pages: _note_fights(page, null, found)
	for event: AdventureEvent in graph.event_hosts:
		var encounter: AdventureEncounter = graph.get_encounter_of(event)
		for page: AdventurePage in AdventureEventGraph.new(event).pages: _note_fights(page, encounter, found)
	return found

static func _note_fights(page: AdventurePage, encounter: AdventureEncounter, found: Dictionary[AdventureFightDecision, MonsterProfile]) -> void:
	for decision: AdventureDecision in page.decisions:
		var fight: AdventureFightDecision = decision as AdventureFightDecision
		if fight == null or found.has(fight): continue
		var monster: MonsterProfile = get_monster(fight, encounter)
		if monster != null: found[fight] = monster

## As the story picks it ([code]Story._create_fight[/code]): the monster of the named encounter or of [param own], else the first enemy
static func get_monster(fight: AdventureFightDecision, own: AdventureEncounter) -> MonsterProfile:
	var encounter: AdventureEncounter = own
	if not fight.encounter.is_empty(): encounter = Files.load_existing(fight.encounter) as AdventureEncounter
	if encounter != null and encounter.profile is MonsterProfile: return encounter.profile as MonsterProfile
	return fight.enemies[0] if not fight.enemies.is_empty() else null

func get_monster_of(fight: AdventureFightDecision) -> MonsterProfile: return _monster_of.get(fight)

func is_running() -> bool: return _runner.is_running()

## Whether the Fight Lab plugin is on, to open a scenario in ([method open_in_lab])
static func has_lab() -> bool: return Engine.has_meta(LAB_META)

## Shows the Fight Lab running the reference fighters against [param monster]
static func open_in_lab(monster: MonsterProfile) -> void:
	var lab: Object = Engine.get_meta(LAB_META, null)
	if lab != null: lab.call(&"open_scenario", make_scenario([monster] as Array[MonsterProfile]))

## Every reference fighter against every monster the adventure fights; false if there is nothing to fight or the lab didn't start
func simulate() -> bool:
	var monsters: Array[MonsterProfile] = _get_monsters()
	if _key.is_empty() or monsters.is_empty() or is_running(): return false
	var settings: FightLabRunSettings = FightLabRunSettings.new()
	settings.scenario = make_scenario(monsters)
	settings.fights = FIGHTS
	settings.max_exchanges = MAX_EXCHANGES
	var keys: Array[String] = []
	for monster: MonsterProfile in monsters: keys.append(_monster_key(monster))
	_pending = {"monsters": keys, "stamps": _get_stamps(settings.scenario)}
	failed = not _runner.start(settings, _file(".settings.tres"), _file(".json"))
	changed.emit()
	return not failed

## The reference fighters against [param monsters], saved in no file
static func make_scenario(monsters: Array[MonsterProfile]) -> FightLabScenario:
	var scenario: FightLabScenario = (load(REFERENCE) as FightLabScenario).duplicate()
	var side_b: Array[ActorProfile] = []
	side_b.assign(monsters)
	scenario.side_b = side_b
	return scenario

## Each reference fighter's numbers against [param fight]'s monster: [{name, stats}] ([method FightLabStats.summarize]); empty: not simulated
func get_odds(fight: AdventureFightDecision) -> Array[Dictionary]:
	var odds: Array[Dictionary] = []
	var monster: MonsterProfile = get_monster_of(fight)
	if monster == null or _result.is_empty(): return odds
	var monsters: Array = _result["monsters"]
	var column: int = monsters.find(_monster_key(monster))
	if column < 0: return odds
	var names: Array = _result["side_a"]
	var cells: Array = _result["cells"]
	for cell: Dictionary in cells:
		var a: int = cell["a"]
		var b: int = cell["b"]
		if b == column: odds.append({"name": str(names[a]), "stats": cell["stats"]})
	return odds

## Whether [param fight]'s monster or the reference fighters changed since they were simulated
func is_out_of_date(fight: AdventureFightDecision) -> bool:
	var monster: MonsterProfile = get_monster_of(fight)
	if monster == null or _result.is_empty(): return false
	var stamps: Dictionary = _result["stamps"]
	for file: String in stamps:
		if not (file == _file_of(monster) or file.begins_with(REFERENCE_MARK)): continue
		var stamp: int = stamps[file]
		if stamp != _stamp(file): return true
	return false

func _on_finished(result: Dictionary) -> void:
	failed = result.is_empty()
	if not failed:
		result.merge(_pending)
		_result = result
		var file: FileAccess = FileAccess.open(_file(".json"), FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify(result))
	changed.emit()

func _get_monsters() -> Array[MonsterProfile]:
	var monsters: Array[MonsterProfile] = []
	for monster: MonsterProfile in _monster_of.values(): if not monsters.has(monster): monsters.append(monster)
	return monsters

## Modified times of the monsters' files, and of the reference scenario and fighters
static func _get_stamps(scenario: FightLabScenario) -> Dictionary[String, int]:
	var stamps: Dictionary[String, int] = {}
	for monster: ActorProfile in scenario.side_b: stamps[_file_of(monster)] = _stamp(_file_of(monster))
	var references: Array[String] = [ResourceUID.uid_to_path(REFERENCE)]
	for fighter: ActorProfile in scenario.side_a: if fighter != null: references.append(_file_of(fighter))
	for reference: String in references: stamps[REFERENCE_MARK + reference] = _stamp(reference)
	return stamps

static func _stamp(file: String) -> int:
	var path: String = file.trim_prefix(REFERENCE_MARK)
	return FileAccess.get_modified_time(path) if not path.is_empty() and FileAccess.file_exists(path) else 0

## The file a profile is saved in (a monster inside an encounter's file: that file)
static func _file_of(profile: ActorProfile) -> String: return profile.resource_path.get_slice("::", 0)

static func _monster_key(monster: MonsterProfile) -> String: return monster.resource_path if not monster.resource_path.is_empty() else monster.name

## Its UID, else (a file without one) its path's hash; none if it isn't saved
static func _key_of(adventure: Adventure) -> String:
	if adventure == null or adventure.resource_path.is_empty(): return ""
	var uid: String = ResourceUID.path_to_uid(adventure.resource_path)
	return uid.trim_prefix("uid://") if uid.begins_with("uid://") else str(adventure.resource_path.hash())

func _file(extension: String) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIRECTORY))
	return DIRECTORY + _key + extension
