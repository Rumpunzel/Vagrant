extends GdUnitTestSuite

## What the adventure editor's rich tooltips say, and that their links name what they show.

var _shore: AdventureLocation
var _ambush: AdventureEvent
var _strikes: AdventurePage

func before_test() -> void:
	_shore = AdventureLocation.new()
	_shore.title = "Shore"
	_shore.description = "Waves."
	_strikes = AdventurePage.new()
	_strikes.title = "Strikes"
	var go_on: AdventureDecision = AdventureDecision.new()
	go_on.description = "Continue."
	go_on.transition = _strikes
	var chance: AdventureChanceCondition = AdventureChanceCondition.new()
	_ambush = AdventureEvent.new()
	_ambush.title = "Ambush"
	_ambush.description = "The water [stirs]."
	_ambush.conditions = [chance] as Array[AdventureCondition]
	_ambush.decisions = [go_on] as Array[AdventureDecision]
	_ambush.decisions_layering = AdventureEvent.Layering.ONLY_THIS
	_ambush.no_rest = true
	TestAdventures.add(_shore, _ambush)

func test_an_event() -> void:
	var text: String = _tooltips().describe(_ambush)
	assert_str(text).contains("[b]Ambush[/b]")
	assert_str(text).contains("[b]Listed at:[/b] [url=%d]" % _shore.get_instance_id())
	assert_str(text).contains("[b]When:[/b] 1 in 2 chance")
	assert_str(text).contains("[b]On the page:[/b] decisions: only its own; no rest here")
	# Its own brackets aren't BBCode
	assert_str(text).contains("[i]The water [lb]stirs].[/i]")
	assert_str(text).contains("• Continue. → [url=%d]" % _strikes.get_instance_id())

func test_links_show_and_open_what_they_name() -> void:
	var tooltips: AdventureTooltips = _tooltips()
	assert_str(tooltips.describe_link(str(_shore.get_instance_id()))).contains("[b]Shore[/b]")
	assert_str(tooltips.describe_link("0")).is_empty()
	var opened: Array[Resource] = [ ]
	tooltips.opened.connect(func(resource: Resource) -> void: opened.append(resource))
	tooltips.open_link(str(_ambush.get_instance_id()))
	assert_array(opened).contains_exactly([_ambush])

func test_an_encounter() -> void:
	var track: AdventureStageTrack = AdventureStageTrack.new()
	track.name = "Storyline"
	track.stages = ["Unmet", "Met"] as Array[String]
	var eleanor: AdventureEncounter = AdventureEncounter.new()
	eleanor.title = "Eleanor"
	eleanor.tracks = [track] as Array[AdventureStageTrack]
	eleanor.events = [_ambush] as Array[AdventureEvent]
	var text: String = _tooltips().describe(eleanor)
	assert_str(text).contains("[b]Eleanor[/b]")
	assert_str(text).contains("[b]Could be at:[/b] ")
	assert_str(text).contains("[b]Storyline:[/b] Unmet → Met")
	assert_str(text).contains("• [url=%d]" % _ambush.get_instance_id())

func _tooltips() -> AdventureTooltips:
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = _shore
	return AdventureTooltips.new(AdventureGraph.new(adventure))
