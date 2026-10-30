extends GdUnitTestSuite

## The adventure editor's event edits as data: references by file, cycles, new pages, decisions and events.

func test_file_path() -> void:
	assert_str(AdventureEventEditing.get_file_path(_page("res://events/ambush.tres"))).is_equal("res://events/ambush.tres")
	assert_str(AdventureEventEditing.get_file_path(_page("res://events/ambush.tres::Resource_a1"))).is_equal("res://events/ambush.tres")
	assert_str(AdventureEventEditing.get_file_path(_page(""))).is_empty()

func test_reference_by_file() -> void:
	var inside: AdventurePage = _page("res://events/ambush.tres::Resource_a1")
	assert_object(AdventureEventEditing.make_reference(inside, "res://events/ambush.tres")).is_same(inside)
	var unsaved: AdventurePage = _page("")
	assert_object(AdventureEventEditing.make_reference(unsaved, "res://events/ambush.tres")).is_same(unsaved)
	var elsewhere: AdventurePage = _page("res://locations/ruin.tres")
	var reference: AdventurePageReference = AdventureEventEditing.make_reference(elsewhere, "res://events/ambush.tres")
	assert_object(reference).is_instanceof(AdventureTransition)
	assert_str((reference as AdventureTransition)._leads_to).is_equal("res://locations/ruin.tres")

func test_cycles_through_held_pages() -> void:
	var ambush: AdventurePage = _page("")
	var lost: AdventurePage = _page("")
	var deeper: AdventurePage = _page("")
	_link(ambush, lost)
	_link(lost, deeper)
	assert_bool(AdventureEventEditing.would_loop(deeper, ambush)).is_true()
	assert_bool(AdventureEventEditing.would_loop(deeper, deeper)).is_true()
	assert_bool(AdventureEventEditing.would_loop(ambush, deeper)).is_false()
	var nested: AdventurePage = _page("")
	deeper.events.append(nested)
	assert_bool(AdventureEventEditing.would_loop(nested, lost)).is_true()

func test_transitions_and_host_references_break_cycles() -> void:
	var ambush: AdventurePage = _page("res://events/ambush.tres")
	var lost: AdventurePage = _page("")
	var decision: AdventureDecision = AdventureDecision.new()
	decision.transition = AdventureTransition.leading_to(lost)
	ambush.decisions.append(decision)
	var back: AdventureDecision = AdventureDecision.new()
	back.transition = AdventureHostReference.new()
	lost.decisions.append(back)
	assert_bool(AdventureEventEditing.would_loop(lost, ambush)).is_false()

func test_pages_inside_the_file_are_not_lost_by_relinking() -> void:
	var ambush: AdventurePage = _page("res://events/ambush.tres")
	var lost: AdventurePage = _page("")
	var on_its_own: AdventurePage = _page("res://events/lost.tres")
	_link(ambush, lost)
	_link(ambush, on_its_own)
	assert_array(AdventureEventEditing.find_references_to(ambush, lost)).contains_exactly([[ambush.decisions[0], &"transition"]])
	var only_way: Array[AdventurePageReference] = [lost]
	assert_bool(AdventureEventEditing.would_lose_page(ambush, only_way)).is_true()
	# A page in its own file stays, whatever points at it
	var own_file: Array[AdventurePageReference] = [on_its_own]
	assert_bool(AdventureEventEditing.would_lose_page(ambush, own_file)).is_false()
	_link(ambush, lost)
	assert_bool(AdventureEventEditing.would_lose_page(ambush, only_way)).is_false()
	var both_ways: Array[AdventurePageReference] = [lost, lost]
	assert_bool(AdventureEventEditing.would_lose_page(ambush, both_ways)).is_true()

func test_new_pages_and_decisions_have_an_id_in_their_file() -> void:
	var page: AdventurePage = AdventureEventEditing.make_page()
	assert_str(page.resource_scene_unique_id).is_not_empty()
	assert_str(AdventureLayout.get_key(page)).is_equal("::" + page.resource_scene_unique_id)
	assert_str(AdventureEventEditing.make_choice().description).is_equal("New choice.")
	var fight: AdventureFightDecision = AdventureEventEditing.make_fight()
	assert_array(fight.enemies).is_empty()
	assert_str(fight.resource_scene_unique_id).is_not_empty()
	assert_object(AdventureEventEditing.make_save().attribute).is_null()

func test_new_events() -> void:
	var event: AdventurePage = AdventureEventEditing.make_event("Wolves", false)
	assert_str(event.title).is_equal("Wolves")
	assert_bool(event is AdventureEventScenario).is_false()
	assert_object(AdventureEventEditing.make_event("Wolves", true)).is_instanceof(AdventureEventScenario)
	var location: AdventurePage = _page("res://locations/swamp/temple_ruin.tres")
	assert_str(AdventureEventEditing.get_event_path(location, "Wolf Pack")).is_equal("res://locations/swamp/events/wolf_pack.tres")
	# A scenario in the events folder already: its options next to it
	var scenario: AdventurePage = _page("res://locations/swamp/events/lurker.tres")
	assert_str(AdventureEventEditing.get_event_path(scenario, "Wolf Pack")).is_equal("res://locations/swamp/events/wolf_pack.tres")

func test_monster_conditions_point_at_the_spawning_page() -> void:
	var lurker: MonsterProfile = TestMonsters.cutthroat()
	var ambush: AdventurePage = _page("res://events/ambush.tres")
	var won: AdventurePage = _page("res://events/won.tres")
	var own: AdventureMonsterCondition = AdventureEventEditing.make_monster_condition(AdventureMonsterCondition.State.CAN_FIGHT, lurker, 0, ambush, ambush)
	assert_object(own.monster.spawned_by).is_null()
	assert_object(own.monster.monster).is_same(lurker)
	var other: AdventureMonsterCondition = AdventureEventEditing.make_monster_condition(AdventureMonsterCondition.State.INCAPACITATED, lurker, 1, ambush, won)
	assert_object(other.monster.spawned_by).is_instanceof(AdventureTransition)
	assert_int(other.monster.index).is_equal(1)
	assert_int(other.state).is_equal(AdventureMonsterCondition.State.INCAPACITATED)
	# Inside the file holding it: pointing back would loop
	var inside: AdventurePage = _page("res://events/ambush.tres::Resource_n1")
	ambush.events.append(inside)
	assert_object(AdventureEventEditing.make_monster_condition(AdventureMonsterCondition.State.DEAD, lurker, 0, ambush, inside)).is_null()

func test_special_references() -> void:
	var host: AdventurePageReference = AdventureEventEditing.make_special_reference(false)
	var previous: AdventurePageReference = AdventureEventEditing.make_special_reference(true)
	assert_object(host).is_instanceof(AdventureHostReference)
	assert_object(previous).is_instanceof(AdventurePreviousLocationReference)
	assert_str(previous.resource_scene_unique_id).is_not_empty()
	var decision: AdventureDecision = AdventureDecision.new()
	decision.transition = previous
	var page: AdventurePage = _page("")
	page.decisions.append(decision)
	var outlet: AdventureEventGraph.Outlet = AdventureEventGraph.get_outlets(page)[0]
	assert_bool(outlet.to_previous).is_true()
	assert_bool(outlet.goes_back()).is_false()

func test_forgetting_a_page() -> void:
	var shore: AdventurePage = _page("res://locations/shore.tres")
	var ruin: AdventurePage = _page("res://locations/ruin.tres")
	var doomed: AdventurePage = _page("")
	var to_doomed: AdventureDecision = AdventureDecision.new()
	to_doomed.transition = doomed
	var elsewhere: AdventureDecision = AdventureDecision.new()
	elsewhere.transition = ruin
	var fight: AdventureFightDecision = AdventureFightDecision.new()
	fight.transition = ruin
	fight.failure_transition = doomed
	shore.decisions = [to_doomed, elsewhere, fight] as Array[AdventureDecision]
	shore.events = [doomed] as Array[AdventurePage]
	ruin.nearby_events = [doomed] as Array[AdventurePage]
	var roots: Array[AdventurePage] = [shore, ruin]
	var changes: Array[Array] = AdventureEventEditing.get_changes_forgetting(doomed, roots)
	assert_array(changes).contains_exactly_in_any_order([
		[fight, &"failure_transition", null, shore],
		[shore, &"decisions", [elsewhere, fight], shore],
		[shore, &"events", [], shore],
		[ruin, &"nearby_events", [], ruin],
	])

func test_forgetting_an_area() -> void:
	var swamp: AdventureArea = AdventureArea.new()
	var ruin: AdventurePage = _page("res://locations/ruin.tres")
	ruin.area = swamp
	var pages: Array[AdventurePage] = [ruin, _page("res://locations/shore.tres")]
	assert_array(AdventureEventEditing.get_changes_forgetting_area(swamp, pages)).contains_exactly([[ruin, &"area", null, ruin]])

func test_consequence_types() -> void:
	var types: Dictionary[String, Script] = AdventureEventEditing.get_consequence_types()
	assert_array(types.keys()).contains(["AdventureInjuryConsequence", "AdventureKillMonsterConsequence"])
	assert_array(types.keys()).not_contains(["AdventureConsequence"])
	assert_str(AdventureEventEditing.get_type_name("AdventureKillMonsterConsequence")).is_equal("Kill Monster")
	assert_str(AdventureEventEditing.get_type_name("AdventureMonsterCondition")).is_equal("Monster")
	assert_array(AdventureEventEditing.get_condition_types().keys()).contains(["AdventureMonsterCondition", "AdventureIsAlwaysTrueCondition"])
	assert_array(AdventureEventEditing.get_condition_types().keys()).not_contains(["AdventureCondition"])
	var injury: AdventureConsequence = AdventureEventEditing.make_consequence(types["AdventureInjuryConsequence"])
	assert_object(injury).is_instanceof(AdventureInjuryConsequence)
	assert_str(injury.resource_scene_unique_id).is_not_empty()

func test_outlets_name_their_property() -> void:
	var save: AdventureSaveDecision = AdventureSaveDecision.new()
	var properties: Array = AdventureEventGraph.get_outcomes(save).map(func(outcome: AdventureEventGraph.Outlet) -> StringName: return outcome.property)
	assert_array(properties).contains_exactly([&"transition", &"failure_transition"])
	var effects: Array = AdventureEventGraph.get_outcomes(save).map(func(outcome: AdventureEventGraph.Outlet) -> StringName: return outcome.consequences_property)
	assert_array(effects).contains_exactly([&"consequences", &"failure_consequences"])
	var fight: AdventureFightDecision = AdventureFightDecision.new()
	fight.back_steps = 2
	var fled: AdventureEventGraph.Outlet = AdventureEventGraph.get_outcomes(fight)[2]
	assert_str(fled.consequences_property).is_empty()
	assert_int(fled.get_back_steps()).is_equal(2)

func _page(path: String) -> AdventurePage:
	var page: AdventurePage = AdventurePage.new()
	if path.contains("::"): page.resource_scene_unique_id = path.get_slice("::", 1)
	if not path.is_empty(): page.resource_path = path
	return page

func _link(from: AdventurePage, to: AdventurePage) -> void:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.transition = to
	from.decisions.append(decision)
