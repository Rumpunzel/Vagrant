extends GdUnitTestSuite

## Items and looting in the adventure editor: the items its menus offer, what a search's card and tooltip say, and the problem of a search that
## finds nothing.

var _shore: AdventureLocation
var _bandit: AdventureEncounter
var _search: AdventureLootDecision

func before_test() -> void:
	_shore = AdventureLocation.new()
	_shore.title = "Shore"
	_shore.area = AdventureArea.new()
	_search = AdventureLootDecision.new()
	_search.description = "Search the bandit."
	var beaten: AdventureEvent = AdventureEvent.new()
	beaten.title = "Beaten"
	beaten.where = AdventureEvent.Where.ANYWHERE
	beaten.decisions = [_search] as Array[AdventureDecision]
	_bandit = AdventureEncounter.new()
	_bandit.title = "Bandit"
	_bandit.events = [beaten] as Array[AdventureEvent]

func test_a_search_that_finds_nothing_is_a_problem() -> void:
	assert_array(_problems()).contains_exactly(["Beaten, \"Search the bandit.\": searching finds nothing (no monster gear, no loot)"])
	_bandit.loot = {ItemProfile.create_item("Rope"): 1} as Dictionary[ItemProfile, int]
	assert_array(_problems()).is_empty()
	_bandit.loot = {} as Dictionary[ItemProfile, int]
	_bandit.profile = TestMonsters.cutthroat()
	assert_array(_problems()).is_empty()

func test_card_and_tooltip_tell_what_it_finds() -> void:
	_bandit.profile = TestMonsters.cutthroat()
	_bandit.loot = {ItemProfile.create_item("Rations"): 2} as Dictionary[ItemProfile, int]
	assert_str(AdventureCardView.describe_loot(_search, _bandit)).is_equal("Loot: Bandit")
	assert_str(AdventureCardView.describe_loot(_search, null)).is_equal("Loot: its encounter")
	var text: String = AdventureTooltips.new(AdventureGraph.new(_adventure())).describe(_search)
	assert_str(text).contains("[b]Finds on Bandit:[/b] Knife, 2 Rations")

func test_the_loot_template_searches_the_dead_monster() -> void:
	var event: AdventureEvent = AdventureMakers.make_loot_event(_bandit)
	assert_str(event.title).is_equal("Searching the Bandit")
	var dead: AdventureMonsterCondition = event.conditions[0] as AdventureMonsterCondition
	assert_int(dead.state).is_equal(AdventureMonsterCondition.State.DEAD)
	assert_str(dead.encounter).is_empty()
	var search: AdventureLootDecision = event.decisions[0] as AdventureLootDecision
	assert_str(search.description).is_equal("Search the Bandit.")
	assert_str(search.encounter).is_empty()
	assert_object(search.transition).is_instanceof(AdventureHostReference)
	assert_int(event.decisions_layering).is_equal(AdventureEvent.Layering.ADDS)

func _adventure() -> Adventure:
	var adventure: Adventure = Adventure.new()
	adventure.starting_page = _shore
	adventure.encounters = [_bandit] as Array[AdventureEncounter]
	return adventure

func _problems() -> Array:
	return AdventureProblems.new(AdventureGraph.new(_adventure()), [] as Array[AdventureEvent]).problems.map(func(problem: AdventureProblems.Problem) -> String: return problem.text)

func test_menus_offer_the_items_found_weapons_first() -> void:
	var directory: String = "user://test_find_items"
	DirAccess.make_dir_recursive_absolute(directory.path_join("deeper"))
	ResourceSaver.save(ItemProfile.create_item("Rope"), directory.path_join("rope.tres"))
	ResourceSaver.save(WeaponProfile.create("Axe", Rules.d8), directory.path_join("deeper/axe.tres"))
	ResourceSaver.save(AdventurePage.new(), directory.path_join("page.tres"))
	var names: Array[String] = []
	for item: ItemProfile in AdventureMakers.find_items(directory): names.append(item.name)
	for path: String in ["rope.tres", "deeper/axe.tres", "page.tres", "deeper"]: DirAccess.remove_absolute(directory.path_join(path))
	DirAccess.remove_absolute(directory)
	assert_array(names).is_equal(["Axe", "Rope"])
