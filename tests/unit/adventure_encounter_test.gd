extends GdUnitTestSuite

## Encounters: their events show where they could be, near it or anywhere, gated by their stages; moves and stage changes.

const CASTLE_PATH: String = "user://encounter_test_castle.tres"
const ENCOUNTER_PATH: String = "user://encounter_test_eleanor.tres"

var _story: Story
var _beach: AdventureArea
var _shore: AdventureLocation
var _castle: AdventureLocation
var _eleanor: AdventureEncounter
var _meeting: AdventureEvent
var _hearing: AdventureEvent

func before_test() -> void:
	_story = auto_free(Story.new())
	_beach = AdventureArea.new()
	_shore = _location("Shore", _beach)
	_castle = _location("Castle", _beach)
	_link(_shore, _castle)
	_link(_castle, _shore)
	_meeting = _event("Meeting", "She knocks.")
	_hearing = _event("", "You hear knocking.")
	_hearing.where = AdventureEvent.Where.NEAR
	var storyline: AdventureStageTrack = AdventureStageTrack.new()
	storyline.name = "Storyline"
	storyline.stages = ["Unmet", "Met"] as Array[String]
	_eleanor = AdventureEncounter.new()
	_eleanor.title = "Eleanor"
	_eleanor.tracks = [storyline] as Array[AdventureStageTrack]
	_eleanor.events = [_meeting, _hearing] as Array[AdventureEvent]
	_story.world = StoryWorld.new([_eleanor] as Array[AdventureEncounter])
	_story.world.move(_eleanor, [_castle] as Array[AdventureLocation])

func after_test() -> void:
	for path: String in [CASTLE_PATH, ENCOUNTER_PATH]: if FileAccess.file_exists(path): DirAccess.remove_absolute(path)

func test_shows_where_it_is_and_near_it() -> void:
	assert_array(_castle.get_events(_story)).contains_exactly([_meeting])
	assert_array(_shore.get_events(_story)).contains_exactly([_hearing])
	assert_str(_shore.get_description(_story)).is_equal("[p]Damp.[/p][p]You hear knocking.[/p]")

func test_could_be_in_several_places() -> void:
	var far: AdventureLocation = _location("Far", _beach)
	_link(_shore, far)
	_story.world.move(_eleanor, [_castle, _shore] as Array[AdventureLocation])
	assert_array(_shore.get_events(_story)).contains_exactly([_meeting])
	assert_array(_castle.get_events(_story)).contains_exactly([_meeting])
	assert_array(far.get_events(_story)).contains_exactly([_hearing])

func test_nowhere_until_placed() -> void:
	_story.world.move(_eleanor, [ ] as Array[AdventureLocation])
	assert_array(_castle.get_events(_story)).is_empty()
	_meeting.where = AdventureEvent.Where.ANYWHERE
	assert_array(_shore.get_events(_story)).contains_exactly([_meeting])

func test_reach_counts_links() -> void:
	var far: AdventureLocation = _location("Far", _beach)
	_link(_shore, far)
	assert_array(far.get_events(_story)).is_empty()
	_hearing.nearby_reach = 2
	_story.world = StoryWorld.new([_eleanor] as Array[AdventureEncounter])
	_story.world.move(_eleanor, [_castle] as Array[AdventureLocation])
	assert_array(far.get_events(_story)).contains_exactly([_hearing])

func test_reach_zero_is_the_whole_area() -> void:
	var swamp: AdventureLocation = _location("Swamp", AdventureArea.new())
	var far: AdventureLocation = _location("Far", _beach)
	_link(_castle, swamp)
	_link(swamp, far)
	_hearing.nearby_reach = 0
	assert_array(swamp.get_events(_story)).is_empty()
	assert_array(far.get_events(_story)).contains_exactly([_hearing])

func test_staying_in_the_area() -> void:
	var swamp: AdventureLocation = _location("Swamp", AdventureArea.new())
	_link(_castle, swamp)
	assert_array(swamp.get_events(_story)).contains_exactly([_hearing])
	_hearing.nearby_stays_in_area = true
	assert_array(swamp.get_events(_story)).is_empty()

func test_only_at_limits_where() -> void:
	_save(_castle, CASTLE_PATH)
	_meeting.where = AdventureEvent.Where.ANYWHERE
	_meeting.only_at = [CASTLE_PATH] as Array[String]
	assert_array(_castle.get_events(_story)).contains_exactly([_meeting])
	assert_array(_shore.get_events(_story)).not_contains([_meeting])

func test_stages_gate_events() -> void:
	assert_str(_story.world.get_stage(_eleanor, "Storyline")).is_equal("Unmet")
	var unmet: AdventureStageCondition = AdventureStageCondition.new()
	unmet.track = "Storyline"
	unmet.stages = ["Unmet"] as Array[String]
	_meeting.conditions = [unmet] as Array[AdventureCondition]
	assert_array(_castle.get_events(_story)).contains_exactly([_meeting])
	_story.world.set_stage(_eleanor, "Storyline", "Met")
	assert_array(_castle.get_events(_story)).is_empty()

func test_consequences_act_on_the_own_encounter_here() -> void:
	_story._encounter = _eleanor
	_story._location = _shore
	AdventureMoveConsequence.new().resolve(_story, 0)
	assert_array(_story.world.get_places(_eleanor)).contains_exactly([_shore])
	var met: AdventureStageConsequence = AdventureStageConsequence.new()
	met.track = "Storyline"
	met.stage = "Met"
	met.resolve(_story, 0)
	assert_str(_story.world.get_stage(_eleanor, "Storyline")).is_equal("Met")

func test_decisions_of_shown_encounter_events_belong_to_them() -> void:
	var greet: AdventureDecision = AdventureDecision.new()
	_meeting.decisions = [greet] as Array[AdventureDecision]
	assert_object(_story._find_decision_owner(_castle, greet)).is_same(_meeting)
	assert_object(_story.world.get_encounter_of(_meeting)).is_same(_eleanor)

func test_the_location_orders_its_own_events_and_encounters() -> void:
	var own: AdventureEvent = _event("", "Wind.")
	TestAdventures.list(_castle, [own] as Array[AdventureEvent])
	var encounters: Array[AdventureEncounter] = [_eleanor]
	assert_array(_castle.get_sources(encounters)).contains_exactly([_castle.scenario, _eleanor])
	_save(_castle, CASTLE_PATH)
	_save(_eleanor, ENCOUNTER_PATH)
	_castle.order = [ENCOUNTER_PATH, CASTLE_PATH] as Array[String]
	assert_array(_castle.get_sources(encounters)).contains_exactly([_eleanor, _castle.scenario])
	assert_str(_castle.get_description(_story)).is_equal("[p]Damp.[/p][p]She knocks.[/p][p]Wind.[/p]")

func test_place_condition() -> void:
	var here: AdventurePlaceCondition = AdventurePlaceCondition.new()
	_story._location = _castle
	assert_bool(here.is_true(_story, _meeting)).is_true()
	_story._location = _shore
	assert_bool(here.is_true(_story, _meeting)).is_false()
	_save(_castle, CASTLE_PATH)
	var at_castle: AdventurePlaceCondition = AdventurePlaceCondition.new()
	at_castle.at = CASTLE_PATH
	assert_bool(at_castle.is_true(_story, _meeting)).is_true()
	_story.world.move(_eleanor, [_shore] as Array[AdventureLocation])
	assert_bool(at_castle.is_true(_story, _meeting)).is_false()
	assert_str(at_castle.describe()).is_equal("It is at Castle")

func test_location_stages_gate_its_own_events() -> void:
	var state: AdventureStageTrack = AdventureStageTrack.new()
	state.name = "Temple"
	state.stages = ["Intact", "Burned"] as Array[String]
	_shore.tracks = [state] as Array[AdventureStageTrack]
	var ashes: AdventureEvent = _event("", "Ashes.")
	var burned: AdventureStageCondition = AdventureStageCondition.new()
	burned.track = "Temple"
	burned.stages = ["Burned"] as Array[String]
	ashes.conditions = [burned] as Array[AdventureCondition]
	TestAdventures.list(_shore, [ashes] as Array[AdventureEvent])
	_story._location = _shore
	assert_array(_shore.get_events(_story)).not_contains([ashes])
	var burn: AdventureStageConsequence = AdventureStageConsequence.new()
	burn.track = "Temple"
	burn.stage = "Burned"
	burn.resolve(_story, 0)
	assert_array(_shore.get_events(_story)).contains([ashes])

func test_the_body_is_its_monsters() -> void:
	_story._monsters = auto_free(Monsters.new())
	_eleanor.profile = TestMonsters.cutthroat()
	var can_fight: AdventureMonsterCondition = AdventureMonsterCondition.new()
	var beaten: AdventureMonsterCondition = AdventureMonsterCondition.new()
	beaten.state = AdventureMonsterCondition.State.BEATEN
	var dead: AdventureMonsterCondition = AdventureMonsterCondition.new()
	dead.state = AdventureMonsterCondition.State.DEAD
	var states: Callable = func() -> Array: return [can_fight.is_true(_story, _meeting), beaten.is_true(_story, _meeting), dead.is_true(_story, _meeting)]
	assert_array(states.call()).is_equal([true, false, false])
	var monster: Monster = _story.get_monster(_eleanor, _eleanor.profile as MonsterProfile)
	monster.incapacitated = true
	assert_array(states.call()).is_equal([false, true, false])
	_story._encounter = _eleanor
	AdventureKillConsequence.new().resolve(_story, 0)
	assert_array(states.call()).is_equal([false, false, true])
	assert_str(beaten.describe()).is_equal("It is beaten")
	# Without a monster it is neither
	_eleanor.profile = null
	assert_bool(can_fight.is_true(_story, _meeting)).is_false()

func test_chance_is_rolled_once_per_arrival() -> void:
	var chance: AdventureChanceCondition = AdventureChanceCondition.new()
	chance.times = 1
	chance.out_of = 3
	_meeting.conditions = [chance] as Array[AdventureCondition]
	var rolls: Array[bool] = [false, true]
	var rolled: Array[int] = [0]
	_story.chance_roller = func(condition: AdventureChanceCondition) -> bool:
		assert_object(condition).is_same(chance)
		rolled[0] += 1
		return rolls[rolled[0] - 1]
	# Asked several times while there (title, text, decisions): one roll
	assert_array(_castle.get_events(_story)).is_empty()
	assert_array(_castle.get_events(_story)).is_empty()
	assert_int(rolled[0]).is_equal(1)
	# The next arrival rolls again
	_story._chance_rolls.clear()
	assert_array(_castle.get_events(_story)).contains_exactly([_meeting])
	assert_str(chance.describe()).is_equal("1 in 3 chance")

func _save(resource: Resource, path: String) -> void:
	ResourceSaver.save(resource, path)
	resource.take_over_path(path)

func _location(title: String, area: AdventureArea) -> AdventureLocation:
	var location: AdventureLocation = AdventureLocation.new()
	location.title = title
	location.description = "Damp."
	location.area = area
	return location

func _event(title: String, description: String) -> AdventureEvent:
	var event: AdventureEvent = AdventureEvent.new()
	event.title = title
	event.description = description
	return event

func _link(from: AdventurePage, to: AdventurePage) -> void:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.transition = to
	from.decisions.append(decision)
