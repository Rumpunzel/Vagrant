extends GdUnitTestSuite

## The adventure editor's map edits as data: links, new locations and areas, their files.

func test_link_is_a_plain_decision_to_the_page() -> void:
	var temple: AdventurePage = _page("Temple Ruin", "res://somewhere/temple_ruin.tres")
	var link: AdventureDecision = AdventureMapEditing.make_link(temple)
	assert_str(link.description).is_equal("Go to Temple Ruin.")
	assert_object(link.transition).is_instanceof(AdventureTransition)
	# No UID for a made-up path: the path itself
	assert_str((link.transition as AdventureTransition)._leads_to).is_equal("res://somewhere/temple_ruin.tres")

func test_transition_leads_by_uid() -> void:
	var rocky_shore: AdventurePage = load("uid://ycd6xhx346l6")  # rocky_shore.tres
	assert_str(AdventureTransition.leading_to(rocky_shore)._leads_to).is_equal("uid://ycd6xhx346l6")

func test_unlink_keeps_fights_saves_and_other_links() -> void:
	var shore: AdventurePage = _page("Shore", "")
	var ruin: AdventurePage = _page("Ruin", "")
	var other: AdventurePage = _page("Other", "")
	var to_ruin: AdventureDecision = _decision(ruin)
	var again_to_ruin: AdventureDecision = _decision(ruin)
	var to_other: AdventureDecision = _decision(other)
	var save: AdventureSaveDecision = AdventureSaveDecision.new()
	save.transition = ruin
	var back: AdventureDecision = AdventureDecision.new()
	shore.decisions = [to_ruin, save, to_other, again_to_ruin, back] as Array[AdventureDecision]
	assert_array(AdventureMapEditing.without_links(shore, ruin)).contains_exactly([save, to_other, back])

func test_new_location_and_area() -> void:
	var area: AdventureArea = AdventureMapEditing.make_area("Swamp")
	assert_str(area.name).is_equal("Swamp")
	var page: AdventurePage = AdventureMapEditing.make_location("Temple Ruin", area)
	assert_str(page.title).is_equal("Temple Ruin")
	assert_object(page.area).is_same(area)

func test_file_paths() -> void:
	var adventure: Adventure = Adventure.new()
	adventure.resource_path = "res://adventures/test_adventure.tres"
	assert_str(AdventureMapEditing.get_area_path(adventure, "Misty Swamp")).is_equal("res://adventures/locations/misty_swamp/misty_swamp.tres")
	var area: AdventureArea = AdventureArea.new()
	area.resource_path = "res://adventures/locations/misty_swamp/misty_swamp.tres"
	assert_str(AdventureMapEditing.get_location_path(area, " Old Temple: Ruin ")).is_equal("res://adventures/locations/misty_swamp/old_temple_ruin.tres")

func test_file_names() -> void:
	assert_str(AdventureMapEditing.get_file_name("  The Lurker's Lair!? ")).is_equal("the_lurker_s_lair.tres")
	assert_str(AdventureMapEditing.get_file_name("Brücke 2")).is_equal("brücke_2.tres")
	assert_str(AdventureMapEditing.get_file_name("?!")).is_equal("untitled.tres")

func _page(title: String, path: String) -> AdventurePage:
	var page: AdventurePage = AdventurePage.new()
	page.title = title
	if not path.is_empty(): page.resource_path = path
	return page

func _decision(to: AdventurePage) -> AdventureDecision:
	var decision: AdventureDecision = AdventureDecision.new()
	decision.transition = to
	return decision
