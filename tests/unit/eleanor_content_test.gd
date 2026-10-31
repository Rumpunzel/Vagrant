extends GdUnitTestSuite

## Content check: Eleanor is an encounter at the castle ruin; she is heard next to it until met, and greeting her places her and sets her met.

const ADVENTURE: String = "uid://dw1vkutmmhnao"  # test_adventure.tres
const ROCKY_SHORE: String = "uid://ycd6xhx346l6"  # rocky_shore.tres
const CASTLE_RUIN: String = "uid://dk3q4ia5u7q6m"  # castle_ruin.tres
const ELEANOR: String = "uid://dkfro0d37xt6n"  # eleanor.tres
const MEETING_ELEANOR: String = "uid://d3cv8d5e65vwh"  # meeting_eleanor.tres
const HEARING_ELEANOR: String = "uid://dffxphat87a8a"  # hearing_eleanor.tres

var _story: Story

func before_test() -> void:
	_story = auto_free(Story.new())
	_story._monsters = auto_free(Monsters.new())
	add_child(_story._monsters)
	_story.world = StoryWorld.new((load(ADVENTURE) as Adventure).encounters)

func test_eleanor_is_an_encounter_at_the_castle_ruin() -> void:
	var eleanor: AdventureEncounter = load(ELEANOR)
	assert_array((load(ADVENTURE) as Adventure).encounters).contains([eleanor])
	assert_array(eleanor.events).contains_exactly([load(MEETING_ELEANOR), load(HEARING_ELEANOR)])
	assert_array(eleanor.get_places()).contains_exactly([load(CASTLE_RUIN)])
	assert_array((load(CASTLE_RUIN) as AdventureLocation).get_own_events()).is_empty()

func test_meeting_at_the_ruin_and_hearing_on_the_shore_until_met() -> void:
	var castle_ruin: AdventureLocation = load(CASTLE_RUIN)
	var rocky_shore: AdventureLocation = load(ROCKY_SHORE)
	assert_array(castle_ruin.get_events(_story)).contains_exactly([load(MEETING_ELEANOR)])
	assert_array(rocky_shore.get_events(_story)).contains_exactly([load(HEARING_ELEANOR)])
	_story.world.set_stage(load(ELEANOR), "Storyline", "Met")
	assert_array(castle_ruin.get_events(_story)).is_empty()
	assert_array(rocky_shore.get_events(_story)).is_empty()

func test_greeting_her_places_her_and_sets_her_met() -> void:
	var greet: AdventureDecision = (load(MEETING_ELEANOR) as AdventureEvent).decisions[0]
	assert_str(greet.description).is_equal("Approach and greet her.")
	_story._location = load(CASTLE_RUIN)
	_story._encounter = load(ELEANOR)
	for consequence: AdventureConsequence in greet.consequences: consequence.resolve(_story, 0)
	assert_array(_story.world.get_places(load(ELEANOR))).contains_exactly([load(CASTLE_RUIN)])
	assert_str(_story.world.get_stage(load(ELEANOR), "Storyline")).is_equal("Met")
