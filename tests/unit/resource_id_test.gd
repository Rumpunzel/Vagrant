extends GdUnitTestSuite

## Resources are named so they can be found again: files by UID (else path), resources inside a file by their ID there, also deep inside.

const PATH: String = "user://resource_id_test_event.tres"

var _event: AdventureEvent
var _scenario: AdventureEventScenario
var _nested: AdventureEvent
var _decision: AdventureDecision
var _item: ItemProfile

func before_test() -> void:
	var event: AdventureEvent = AdventureEvent.new()
	var scenario: AdventureEventScenario = AdventureEventScenario.new()
	var nested: AdventureEvent = AdventureEvent.new()
	var decision: AdventureDecision = AdventureDecision.new()
	decision.transition = scenario
	nested.decisions = [AdventureDecision.new()] as Array[AdventureDecision]
	scenario.events = [nested] as Array[AdventureEvent]
	event.decisions = [decision] as Array[AdventureDecision]
	var held: Dictionary[ItemProfile, int] = {ItemProfile.new(): 2}
	event.set_meta("items", held)
	ResourceSaver.save(event, PATH)
	_event = ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_REPLACE)
	_decision = _event.decisions[0]
	_scenario = _decision.transition as AdventureEventScenario
	_nested = _scenario.events[0]
	var items: Dictionary = _event.get_meta("items")
	_item = items.keys()[0]

func after_test() -> void:
	if FileAccess.file_exists(PATH): DirAccess.remove_absolute(PATH)

func test_file_by_uid() -> void:
	assert_str(ResourceId.of(load("uid://idhrvrfm5at"))).is_equal("uid://idhrvrfm5at")  # files.gd

func test_file_without_uid_by_path() -> void:
	assert_str(ResourceId.of(_event)).is_equal(PATH)
	assert_object(ResourceId.find(PATH)).is_same(_event)

func test_inside_a_file() -> void:
	for inside: Resource in [_decision, _scenario, _nested, _nested.decisions[0], _item]:
		var id: String = ResourceId.of(inside)
		assert_str(id).starts_with(PATH + ResourceId.SEPARATOR)
		assert_object(ResourceId.find(id)).is_same(inside)

## A file is indexed once; something added to it later (in the adventure editor) is still found
func test_finds_what_was_added_after_indexing() -> void:
	assert_object(ResourceId.find(ResourceId.of(_decision))).is_same(_decision)
	var added: AdventureDecision = AdventureDecision.new()
	_nested.decisions.append(added)
	ResourceSaver.save(_event, PATH)
	# Loaded again into the same file (as the editor keeps it): the new decision now has an ID in there
	var reloaded: AdventureEvent = ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_REPLACE)
	var scenario: AdventureEventScenario = reloaded.decisions[0].transition as AdventureEventScenario
	var found_later: AdventureDecision = scenario.events[0].decisions[1]
	assert_str(ResourceId.of(found_later)).starts_with(PATH + ResourceId.SEPARATOR)
	assert_object(ResourceId.find(ResourceId.of(found_later))).is_same(found_later)

func test_made_at_runtime_has_no_name() -> void:
	assert_str(ResourceId.of(AdventureDecision.new())).is_empty()
	assert_str(ResourceId.of(null)).is_empty()
	assert_object(ResourceId.find("")).is_null()

func test_gone() -> void:
	assert_object(ResourceId.find("user://resource_id_test_missing.tres")).is_null()
	assert_object(ResourceId.find("uid://bxxxxxxxxxxxx")).is_null()
	assert_object(ResourceId.find(PATH + ResourceId.SEPARATOR + "Resource_gone")).is_null()
