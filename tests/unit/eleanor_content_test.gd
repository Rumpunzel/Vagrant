extends GdUnitTestSuite

## Content check: Hearing Eleanor belongs to The Mysterious Woman and is heard next to the castle ruin, not listed on the rocky shore.

const ROCKY_SHORE: String = "uid://ycd6xhx346l6"  # rocky_shore.tres
const CASTLE_RUIN: String = "uid://dk3q4ia5u7q6m"  # castle_ruin.tres
const MEETING_ELEANOR: String = "uid://d3cv8d5e65vwh"  # meeting_eleanor.tres
const HEARING_ELEANOR: String = "uid://dffxphat87a8a"  # hearing_eleanor.tres

func test_hearing_eleanor_is_nearby_the_woman() -> void:
	var meeting: AdventurePage = load(MEETING_ELEANOR)
	assert_array(meeting.nearby_events).contains_exactly([load(HEARING_ELEANOR)])
	assert_bool((load(CASTLE_RUIN) as AdventurePage).events.has(meeting)).is_true()
	var rocky_shore: AdventurePage = load(ROCKY_SHORE)
	assert_bool(rocky_shore.events.has(load(HEARING_ELEANOR))).is_false()
	assert_array(rocky_shore.find_nearby_events()).contains_exactly([[load(HEARING_ELEANOR), load(CASTLE_RUIN)]])
