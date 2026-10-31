extends GdUnitTestSuite

## The adventure editor's Inspector for UID fields: which properties it takes over (along the script's bases), and which resources it can point at.

func test_fields_along_the_bases() -> void:
	assert_array(AdventureUidInspector.get_field(AdventureEncounter.new().get_script(), "places")).is_equal(["AdventureLocation", ""])
	# An encounter is an event: only_at comes from AdventureEvent
	assert_str(AdventureUidInspector.get_field(AdventureEncounter.new().get_script(), "only_at")[0]).is_equal("AdventureLocation,AdventureArea")
	assert_str(AdventureUidInspector.get_field(AdventureMoveConsequence.new().get_script(), "to")[1]).is_equal("here")
	assert_array(AdventureUidInspector.get_field(AdventureLocation.new().get_script(), "title")).is_empty()

func test_only_files_of_their_own_can_be_pointed_at() -> void:
	var location: AdventureLocation = AdventureLocation.new()
	location.resource_path = "res://locations/ruin.tres"
	assert_str(AdventureUidInspector.get_uid(location)).is_equal("res://locations/ruin.tres")
	assert_str(AdventureUidInspector.get_uid(AdventureLocation.new())).is_empty()
	assert_str(AdventureUidInspector.get_uid(null)).is_empty()
